#ifndef MYRUNACTION_HH
#define MYRUNACTION_HH

#include <G4UserRunAction.hh>
#include <G4ThreeVector.hh>
#include <G4String.hh>

class MyRunAction : public G4UserRunAction {
public:
    MyRunAction(G4int nx, G4int ny, G4int nz, G4double voxelMass);
    virtual ~MyRunAction();

    virtual G4Run* GenerateRun() override;
    virtual void EndOfRunAction(const G4Run* run) override;

private:
    G4int fNx, fNy, fNz;
    G4double fVoxelMass;
};

#endif
