    #include "MyDoseDeposit.hh"

    #include "G4Step.hh"
    #include <G4SystemOfUnits.hh>
    #include "G4TouchableHistory.hh"
    #include "G4Track.hh"
    #include "G4VTouchable.hh"
    #include "G4ParticleDefinition.hh"
    #include "G4RunManager.hh"
    #include "MyRun.hh"

    MyDoseDeposit::MyDoseDeposit(G4int nx, G4int ny, G4int nz)
        : G4VSensitiveDetector("MyDoseDeposit"), fNx(nx), fNy(ny), fNz(nz) {}

    MyDoseDeposit::~MyDoseDeposit() {}

    G4bool MyDoseDeposit::ProcessHits(G4Step* step, G4TouchableHistory*) {
        auto edep = step->GetTotalEnergyDeposit();
        if (edep <= 0.) return false;

        const auto touchable = step->GetPreStepPoint()->GetTouchable();
        if (touchable->GetHistoryDepth() < 3) {
            G4cerr << "❌ Touchable con profundidad insuficiente: "
                   << touchable->GetHistoryDepth() << G4endl;
            return false;
        }

        G4int ix = touchable->GetReplicaNumber(0);  // X
        G4int iy = touchable->GetReplicaNumber(1);  // Y
        G4int iz = touchable->GetReplicaNumber(2);  // Z

        if (ix < 0 || ix >= fNx || iy < 0 || iy >= fNy || iz < 0 || iz >= fNz) {
            G4cerr << "⚠ Índices fuera de rango: (" << ix << "," << iy << "," << iz << ")" << G4endl;
            return false; // Previene crash
        }

        const auto track = step->GetTrack();
        const auto pname = track->GetDefinition()->GetParticleName();

        // Obtención segura del Run
        auto runManager = G4RunManager::GetRunManager();
        if (!runManager) {
            G4cerr << "❌ No se pudo obtener RunManager.\n";
            return false;
        }

        auto runBase = runManager->GetNonConstCurrentRun();
        auto run = dynamic_cast<MyRun*>(runBase);
        if (!run) {
            G4cerr << "❌ No se pudo obtener MyRun desde ProcessHits.\n";
            return false;
        }

        if (track->GetParentID() == 0) {
            run->AddPrimaryEdep(iz, iy, ix, edep);
        } else {
            run->AddSecondaryEdep(iz, iy, ix, edep, pname);
        }

        run->AddTotalEdep(iz, iy, ix, edep);
        return true;
    }


