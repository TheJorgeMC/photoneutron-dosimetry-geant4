#include "MyActionInitialization.hh"
#include "PrimaryGeneratorAction.hh"
#include "MyRunAction.hh"
#include "SteppingAction.hh"

MyActionInitialization::MyActionInitialization(PrimaryGeneratorAction* genAction,
                                               G4int nx, G4int ny, G4int nz, G4double voxelMass)
    : G4VUserActionInitialization(),
      fGenAction(genAction), fNx(nx), fNy(ny), fNz(nz), fVoxelMass(voxelMass) {}

MyActionInitialization::~MyActionInitialization() {}

void MyActionInitialization::Build() const {
    SetUserAction(new PrimaryGeneratorAction(*fGenAction));
    SetUserAction(new MyRunAction(fNx, fNy, fNz, fVoxelMass));

    SetUserAction(new SteppingAction());
    G4cout << "🚀 Build ejecutado\n";
}

void MyActionInitialization::BuildForMaster() const {
    SetUserAction(new MyRunAction(fNx, fNy, fNz, fVoxelMass));
    G4cout << "🚀 BuildForMaster ejecutado\n";
}
