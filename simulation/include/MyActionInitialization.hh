#ifndef MYACTIONINITIALIZATION_HH
#define MYACTIONINITIALIZATION_HH

#include <G4VUserActionInitialization.hh>
#include "PrimaryGeneratorAction.hh"

class MyActionInitialization : public G4VUserActionInitialization {
public:
    MyActionInitialization(PrimaryGeneratorAction* genAction, G4int nx, G4int ny, G4int nz, G4double voxelMass);
    virtual ~MyActionInitialization();

    virtual void Build() const override;
    virtual void BuildForMaster() const override;

private:
    PrimaryGeneratorAction* fGenAction;
    G4int fNx, fNy, fNz;
    G4double fVoxelMass;
};

#endif
