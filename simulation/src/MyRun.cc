#include "MyRun.hh"
#include "G4SystemOfUnits.hh" // Es buena práctica incluir las unidades si las usas
#include "G4Threading.hh"
#include <vector>

MyRun::MyRun() : fNx(0), fNy(0), fNz(0) {}

MyRun::~MyRun() {}

void MyRun::SetVoxelDimensions(G4int nx, G4int ny, G4int nz) {
    fNx = nx;
    fNy = ny;
    fNz = nz;
    InitializeMaps();
    if (G4Threading::IsMasterThread()){
        G4cout << "📐 SetVoxelDimensions: " << fNx << "×" << fNy << "×" << fNz << G4endl;
    }
}

void MyRun::InitializeMaps() {
    // Usamos assign para asegurar que las matrices tengan el tamaño correcto desde el principio
    fEdepTotal.assign(fNz, std::vector<std::vector<G4double>>(fNy, std::vector<G4double>(fNx, 0.0)));
    fEdepPrimary = fEdepTotal; // Copia la estructura ya creada y la llena de ceros
    fEdepSecondary.clear();    // Limpia el mapa de partículas secundarias
    if(G4Threading::IsMasterThread()){
        G4cout << "🧊 InitializeMaps ejecutado\n";
    }
}

bool MyRun::IsValidIndex(int ix, int iy, int iz) const {
    return ix >= 0 && ix < fNx && iy >= 0 && iy < fNy && iz >= 0 && iz < fNz;
}

void MyRun::AddTotalEdep(G4int iz, G4int iy, G4int ix, G4double edep) {
    if (IsValidIndex(ix, iy, iz)) {
        fEdepTotal[iz][iy][ix] += edep;
    }
}

void MyRun::AddPrimaryEdep(G4int iz, G4int iy, G4int ix, G4double edep) {
    if (IsValidIndex(ix, iy, iz)) {
        fEdepPrimary[iz][iy][ix] += edep;
    }
}

// -----------------------------------------------------------------------------
// VERSIÓN OPTIMIZADA DE AddSecondaryEdep
// -----------------------------------------------------------------------------
void MyRun::AddSecondaryEdep(G4int iz, G4int iy, G4int ix, G4double edep, const G4String& pname) {
    if (!IsValidIndex(ix, iy, iz)) return;

    // 1. Busca la rejilla de la partícula usando find() para evitar la creación automática
    auto it = fEdepSecondary.find(pname);

    // 2. Si no se encuentra (es la primera vez que vemos esta partícula), la creamos
    if (it == fEdepSecondary.end()) {
        // 'emplace' es la forma más eficiente de insertar. Creamos la rejilla 3D
        // completa y la insertamos en el mapa. 'it' ahora apuntará al nuevo elemento.
        it = fEdepSecondary.emplace(pname,
            std::vector<std::vector<std::vector<G4double>>>(fNz,
                std::vector<std::vector<G4double>>(fNy,
                    std::vector<G4double>(fNx, 0.0)))
        ).first;
    }

    // 3. 'it->second' es la rejilla 3D. Ahora simplemente añadimos la energía.
    // Esta operación es extremadamente rápida.
    it->second[iz][iy][ix] += edep;
}

const std::vector<std::vector<std::vector<G4double>>>& MyRun::GetTotalEdep() const {
    return fEdepTotal;
}

const std::vector<std::vector<std::vector<G4double>>>& MyRun::GetPrimaryEdep() const {
    return fEdepPrimary;
}

const std::map<G4String, std::vector<std::vector<std::vector<G4double>>>>& MyRun::GetSecondaryEdep() const {
    return fEdepSecondary;
}

// -----------------------------------------------------------------------------
// VERSIÓN OPTIMIZADA DE Merge
// -----------------------------------------------------------------------------
void MyRun::Merge(const G4Run* run) {
    const MyRun* localRun = dynamic_cast<const MyRun*>(run);
    if (!localRun) return;

    // Inicializa los mapas del run maestro si están vacíos
    if (fEdepTotal.empty() && !localRun->fEdepTotal.empty()) {
        fNx = localRun->fNx;
        fNy = localRun->fNy;
        fNz = localRun->fNz;
        InitializeMaps();
        G4cout << "📦 Inicializando mapas en maestro desde Merge()\n";
    }

    // Suma las dosis totales y primarias (esto ya era eficiente)
    for (G4int iz = 0; iz < fNz; ++iz) {
        for (G4int iy = 0; iy < fNy; ++iy) {
            for (G4int ix = 0; ix < fNx; ++ix) {
                fEdepTotal[iz][iy][ix] += localRun->fEdepTotal[iz][iy][ix];
                fEdepPrimary[iz][iy][ix] += localRun->fEdepPrimary[iz][iy][ix];
            }
        }
    }

    // Combina los mapas de dosis secundarias usando la lógica optimizada
    for (const auto& [pname, localGrid] : localRun->fEdepSecondary) {
        // Busca la rejilla en el mapa maestro
        auto it = fEdepSecondary.find(pname);

        // Si no existe, la creamos completa
        if (it == fEdepSecondary.end()) {
            it = fEdepSecondary.emplace(pname,
                std::vector<std::vector<std::vector<G4double>>>(fNz,
                    std::vector<std::vector<G4double>>(fNy,
                        std::vector<G4double>(fNx, 0.0)))
            ).first;
        }

        // Sumamos la dosis del run local a la rejilla del run maestro
        auto& masterGrid = it->second;
        for (G4int iz = 0; iz < fNz; ++iz) {
            for (G4int iy = 0; iy < fNy; ++iy) {
                for (G4int ix = 0; ix < fNx; ++ix) {
                    masterGrid[iz][iy][ix] += localGrid[iz][iy][ix];
                }
            }
        }
    }

    // Llama a la función Merge de la clase base
    G4Run::Merge(run);
}