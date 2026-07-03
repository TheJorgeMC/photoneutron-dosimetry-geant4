#include "MyRunAction.hh"
#include "MyRun.hh"

#include <G4SystemOfUnits.hh>
#include <G4Run.hh>
#include <G4Threading.hh>
#include <G4ios.hh>

#include <fstream>
#include <sstream>
#include <filesystem>
#include <thread>
#include <future>
#include <chrono>

namespace fs = std::filesystem;

MyRunAction::MyRunAction(G4int nx, G4int ny, G4int nz, G4double voxelMass)
    : fNx(nx), fNy(ny), fNz(nz), fVoxelMass(voxelMass) {
    G4cout << "🧮 Constructor MyRunAction: "
           << nx << "x" << ny << "x" << nz << ", m = " << voxelMass / g << " g\n";        
}

MyRunAction::~MyRunAction() {}

G4Run* MyRunAction::GenerateRun() {
    auto run = new MyRun();
    run->SetVoxelDimensions(fNx, fNy, fNz);
    return run;
}

void MyRunAction::EndOfRunAction(const G4Run* run) {
    auto t0 = std::chrono::high_resolution_clock::now();
    if (!G4Threading::IsMasterThread()) return;

    const MyRun* myRun = dynamic_cast<const MyRun*>(run);
    if (!myRun) return;

    const auto& totalMap   = myRun->GetTotalEdep();
    const auto& primaryMap = myRun->GetPrimaryEdep();
    const auto& secMap     = myRun->GetSecondaryEdep();

    if (totalMap.empty() || fVoxelMass == 0.0) {
        G4cout << "❌ Mapa vacío o masa de voxel nula. Abortando.\n";
        return;
    }

    struct VoxelCore {
        int ix, iy, iz;
        double doseTotal;
        double dosePrimary;
        std::map<std::string, double> doseSec;
    };

    std::vector<VoxelCore> voxelList;
    const int nThreads = std::thread::hardware_concurrency();
    std::vector<std::future<std::vector<VoxelCore>>> futures;

    for (int t = 0; t < nThreads; ++t) {
        futures.emplace_back(std::async(std::launch::async, [&, t]() {
            std::vector<VoxelCore> local;
            for (int iz = t; iz < fNz; iz += nThreads) {
                for (int iy = 0; iy < fNy; ++iy) {
                    for (int ix = 0; ix < fNx; ++ix) {
                        if (iz >= totalMap.size() || iy >= totalMap[iz].size() || ix >= totalMap[iz][iy].size())
                            continue;

                        double doseTot = (totalMap[iz][iy][ix] / fVoxelMass) / gray;
                        if (doseTot == 0.0) continue;

                        double dosePrim = 0.0;
                        if (iz < primaryMap.size() &&
                            iy < primaryMap[iz].size() &&
                            ix < primaryMap[iz][iy].size())
                            dosePrim = (primaryMap[iz][iy][ix] / fVoxelMass) / gray;

                        std::map<std::string, double> secVals;
                        for (const auto& [ptype, grid] : secMap) {
                            double val = 0.0;
                            if (iz < grid.size() &&
                                iy < grid[iz].size() &&
                                ix < grid[iz][iy].size())
                                val = (grid[iz][iy][ix] / fVoxelMass) / gray;
                            secVals[ptype] = val;
                        }

                        local.push_back({ix, iy, iz, doseTot, dosePrim, secVals});
                    }
                }
            }
            return local;
        }));
    }

    for (auto& fut : futures) {
        auto chunk = fut.get();
        voxelList.insert(voxelList.end(), chunk.begin(), chunk.end());
    }

    // Escritura por hilos
    for (int t = 0; t < nThreads; ++t) {
        std::ostringstream oss;
        oss << "temp_output_" << t << ".csv";
        std::ofstream outFile(oss.str());
        outFile << "X,Y,Z,DosisTotal,DosisPrimaria";
        for (const auto& [ptype, _] : secMap)
            outFile << ",Sec_" << ptype;
        outFile << "\n";

        for (size_t i = t; i < voxelList.size(); i += nThreads) {
            const auto& v = voxelList[i];
            outFile << v.ix << "," << v.iy << "," << v.iz << ","
                    << v.doseTotal << "," << v.dosePrimary;
            for (const auto& [ptype, val] : v.doseSec)
                outFile << "," << val;
            outFile << "\n";
        }

        outFile.flush();
        outFile.close();
    }

    // Fusión
    std::ofstream merged("output_final.csv");
    merged << "X,Y,Z,DosisTotal,DosisPrimaria";
    for (const auto& [ptype, _] : secMap)
        merged << ",Sec_" << ptype;
    merged << "\n";

    for (int t = 0; t < nThreads; ++t) {
        std::ostringstream fname;
        fname << "temp_output_" << t << ".csv";
        std::ifstream in(fname.str());
        std::string line;
        std::getline(in, line); // skip header
        while (std::getline(in, line)) {
            merged << line << "\n";
        }
        in.close();
        fs::remove(fname.str());  // 🔥 borrar temporal
    }

    merged.close();

    auto t1 = std::chrono::high_resolution_clock::now();
    auto dur = std::chrono::duration_cast<std::chrono::seconds>(t1 - t0).count();
    G4cout << "✅ output_final.csv generado y archivos temporales eliminados.\n";
    G4cout << "⏱ EndOfRunAction tomó " << dur << " segundos.\n";
}
