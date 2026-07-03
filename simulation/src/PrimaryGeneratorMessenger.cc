#include "PrimaryGeneratorMessenger.hh"
#include "PrimaryGeneratorAction.hh"

#include <G4UIparameter.hh>
#include <G4Tokenizer.hh>
#include <G4SystemOfUnits.hh>
#include <G4UIcmdWithAString.hh>
#include <G4UIcmdWithADoubleAndUnit.hh>
#include <G4Threading.hh>  // IMPORTANTE para multihilo

PrimaryGeneratorMessenger::PrimaryGeneratorMessenger(PrimaryGeneratorAction* gen)
    : fGenerator(gen)
{
    fSetParticleCmd = new G4UIcmdWithAString("/generator/setParticle", this);
    fSetParticleCmd->SetGuidance("Selecciona partícula estándar (proton, e-, gamma, etc)");
    fSetParticleCmd->SetParameterName("particle", false);

    fSetEnergyCmd = new G4UIcmdWithADoubleAndUnit("/generator/setParticleEnergy", this);
    fSetEnergyCmd->SetGuidance("Fija la energía de la partícula (proton, gamma, etc)");
    fSetEnergyCmd->SetParameterName("energy", false);
    fSetEnergyCmd->SetUnitCategory("Energy");

    fSetSSDCmd = new G4UIcmdWithADoubleAndUnit("/generator/setSSD", this);
    fSetSSDCmd->SetGuidance("Fija la distancia fuente-superficie (SSD)");
    fSetSSDCmd->SetParameterName("ssd", false);
    fSetSSDCmd->SetUnitCategory("Length");

    fSetIonCmd = new G4UIcommand("/generator/setIon", this);
    fSetIonCmd->SetGuidance("Define un ion: Z A Energía [unidad]");

    auto pZ = new G4UIparameter("Z", 'i', false);
    auto pA = new G4UIparameter("A", 'i', false);
    auto pE = new G4UIparameter("E", 'd', false);
    auto pUnit = new G4UIparameter("unit", 's', true);
    pUnit->SetDefaultValue("MeV");

    fSetIonCmd->SetParameter(pZ);
    fSetIonCmd->SetParameter(pA);
    fSetIonCmd->SetParameter(pE);
    fSetIonCmd->SetParameter(pUnit);
}

PrimaryGeneratorMessenger::~PrimaryGeneratorMessenger() {
    delete fSetParticleCmd;
    delete fSetSSDCmd;
    delete fSetIonCmd;
    delete fSetEnergyCmd;
}

void PrimaryGeneratorMessenger::SetNewValue(G4UIcommand* command, G4String value) {
    // Solo el hilo maestro puede modificar el generador
    if (!G4Threading::IsMasterThread()) return;

    if (command == fSetParticleCmd) {
        fGenerator->SetParticleType(value);
        G4cout << ">> Partícula establecida: " << value << G4endl;
    }
    else if (command == fSetSSDCmd) {
        fGenerator->SetSSD(fSetSSDCmd->GetNewDoubleValue(value));
        G4cout << ">> SSD establecido: " << fGenerator->GetSSD()/cm << " cm" << G4endl;
    }
    else if (command == fSetIonCmd) {
        G4Tokenizer tok(value);
        G4int Z = G4UIcommand::ConvertToInt(tok());
        G4int A = G4UIcommand::ConvertToInt(tok());
        G4double E = G4UIcommand::ConvertToDouble(tok());
        G4String unit = tok();
        if (unit == "") unit = "MeV";
        G4double energy = G4UIcommand::ConvertToDimensionedDouble(G4String(std::to_string(E) + " " + unit));

        fGenerator->SetIon("userIon", Z, A, energy);

        G4cout << ">> Ion establecido: Z=" << Z << ", A=" << A << ", Energía=" << energy / MeV << " MeV" << G4endl;
    }
    else if (command == fSetEnergyCmd) {
        fGenerator->SetParticleEnergy(fSetEnergyCmd->GetNewDoubleValue(value));
        G4cout << ">> Energía de la partícula establecida: " << fSetEnergyCmd->GetNewDoubleValue(value) / MeV << " MeV" << G4endl;
    }
    else {
        G4cerr << "ERROR: Comando desconocido: " << command->GetCommandName() << G4endl;
    }
}
