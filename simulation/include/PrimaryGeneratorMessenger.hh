#ifndef PRIMARY_GENERATOR_MESSENGER_HH
#define PRIMARY_GENERATOR_MESSENGER_HH

#include <G4UImessenger.hh>
#include <G4UIcmdWithAString.hh>
#include <G4UIcmdWithADoubleAndUnit.hh>
#include <G4UIcommand.hh>

class PrimaryGeneratorAction;

class PrimaryGeneratorMessenger : public G4UImessenger {
public:
    PrimaryGeneratorMessenger(PrimaryGeneratorAction* gen);
    virtual ~PrimaryGeneratorMessenger();

    void SetNewValue(G4UIcommand* command, G4String value) override;

private:
    PrimaryGeneratorAction* fGenerator;

    G4UIcmdWithAString* fSetParticleCmd;
    G4UIcmdWithADoubleAndUnit* fSetSSDCmd;
    G4UIcommand* fSetIonCmd;
    G4UIcmdWithADoubleAndUnit* fSetEnergyCmd;
};

#endif
