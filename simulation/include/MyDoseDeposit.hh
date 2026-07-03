
#ifndef MYDOSEDEPOSIT_HH
#define MYDOSEDEPOSIT_HH

#include <G4VSensitiveDetector.hh>

class MyDoseDeposit : public G4VSensitiveDetector {
public:
    MyDoseDeposit(G4int nx, G4int ny, G4int nz);
    virtual ~MyDoseDeposit();
    virtual G4bool ProcessHits(G4Step*, G4TouchableHistory*) override;

private:
    G4int fNx, fNy, fNz;
};


#endif
