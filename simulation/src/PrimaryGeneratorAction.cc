#include "PrimaryGeneratorAction.hh"
#include <G4ParticleTable.hh>
#include <G4Event.hh>
#include <G4IonTable.hh>
#include <G4Exception.hh>
#include <G4Threading.hh>

PrimaryGeneratorAction::PrimaryGeneratorAction() {
    fParticleGun = new G4ParticleGun(1);
    fParticleGun->SetParticleMomentumDirection(G4ThreeVector(0., 0., 1.));

    SetSSD(100. * cm);  // por defecto

    fUseIon = false;
    fIonZ = 6;
    fIonA = 12;
    fIonE = 1200. * MeV;

    fMessenger = G4Threading::IsMasterThread() ? new PrimaryGeneratorMessenger(this) : nullptr;
}

PrimaryGeneratorAction::PrimaryGeneratorAction(const PrimaryGeneratorAction& other) {
    fParticleGun = new G4ParticleGun(1);
    fParticleGun->SetParticleMomentumDirection(G4ThreeVector(0., 0., 1.));

    fSSD = other.fSSD;
    fUseIon = other.fUseIon;
    fIonZ = other.fIonZ;
    fIonA = other.fIonA;
    fIonE = other.fIonE;

    UpdateSourcePosition();

    fMessenger = nullptr;  // no se copia a hilos secundarios
}

PrimaryGeneratorAction::~PrimaryGeneratorAction() {
    delete fParticleGun;
    delete fMessenger;
}

void PrimaryGeneratorAction::GeneratePrimaries(G4Event* anEvent) {
    if (fUseIon) {
        G4IonTable* ionTable = G4ParticleTable::GetParticleTable()->GetIonTable();
        G4ParticleDefinition* ion = ionTable->GetIon(fIonZ, fIonA, 0.);
        if (!ion) {
            G4Exception("PrimaryGeneratorAction::GeneratePrimaries",
                        "IonNotFound", FatalException,
                        "El ion solicitado no está disponible.");
        }
        fParticleGun->SetParticleDefinition(ion);
        fParticleGun->SetParticleEnergy(fIonE);
    }

    fParticleGun->GeneratePrimaryVertex(anEvent);
    // G4cout << "Disparando partícula desde: "
    //    << fParticleGun->GetParticlePosition() / cm << " cm, con energía "
    //    << fParticleGun->GetParticleEnergy() / MeV << " MeV" << G4endl;
}

void PrimaryGeneratorAction::SetParticleType(const G4String& name) {
    G4ParticleDefinition* particle = G4ParticleTable::GetParticleTable()->FindParticle(name);
    if (particle) {
        fParticleGun->SetParticleDefinition(particle);
        fUseIon = false;
    } else {
        G4cerr << "ERROR: Partícula \"" << name << "\" no encontrada." << G4endl;
    }
}

void PrimaryGeneratorAction::SetParticleEnergy(G4double energy) {
    fParticleGun->SetParticleEnergy(energy);
}

void PrimaryGeneratorAction::SetIon(const G4String& /*ionName*/, G4int Z, G4int A, G4double energy) {
    fIonZ = Z;
    fIonA = A;
    fIonE = energy;
    fUseIon = true;
}

void PrimaryGeneratorAction::SetSSD(G4double ssd) {
    if (ssd < 1. * cm || ssd > 500. * cm) {
        G4cerr << "Advertencia: SSD fuera del rango clínico típico (" << ssd/cm << " cm)" << G4endl;
    }
    fSSD = ssd;
    UpdateSourcePosition();
}

void PrimaryGeneratorAction::UpdateSourcePosition() {
    G4double phantomFrontZ = -15. * cm;
    G4double sourceZ = phantomFrontZ - fSSD;

    fParticleGun->SetParticlePosition(G4ThreeVector(0., 0., sourceZ));

    G4cout << "Fuente posicionada en Z = " << sourceZ/cm << " cm (con SSD = "
           << fSSD/cm << " cm)" << G4endl;
}

G4double PrimaryGeneratorAction::GetSSD() const {
    return fSSD;
}
