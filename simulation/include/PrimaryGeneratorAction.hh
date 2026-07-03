#ifndef PRIMARY_GENERATOR_ACTION_HH
#define PRIMARY_GENERATOR_ACTION_HH

#include <G4VUserPrimaryGeneratorAction.hh>
#include <G4ParticleGun.hh>
#include <G4ParticleDefinition.hh>
#include <G4ThreeVector.hh>
#include <G4SystemOfUnits.hh>
#include <G4IonTable.hh>
#include <G4String.hh>

#include "PrimaryGeneratorMessenger.hh"

class PrimaryGeneratorAction : public G4VUserPrimaryGeneratorAction {
public:
    PrimaryGeneratorAction();
    PrimaryGeneratorAction(const PrimaryGeneratorAction& other); // <- copia segura
    virtual ~PrimaryGeneratorAction();

    virtual void GeneratePrimaries(G4Event*);

    void SetParticleType(const G4String& name);
    void SetParticleEnergy(G4double energy);
    void SetIon(const G4String& ionName, G4int Z, G4int A, G4double energy);
    void SetSSD(G4double ssd);
    G4double GetSSD() const;

private:
    G4ParticleGun* fParticleGun;
    G4double fSSD;
    PrimaryGeneratorMessenger* fMessenger;

    G4bool fUseIon;
    G4int fIonZ;
    G4int fIonA;
    G4double fIonE;

    void UpdateSourcePosition();
};

#endif
