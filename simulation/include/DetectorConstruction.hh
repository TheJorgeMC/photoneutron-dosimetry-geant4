#ifndef DETECTOR_CONSTRUCTION_HH
#define DETECTOR_CONSTRUCTION_HH

#include <G4VUserDetectorConstruction.hh>
#include <G4LogicalVolume.hh>
#include <G4VPhysicalVolume.hh>
#include <G4MultiFunctionalDetector.hh>
#include <G4SDManager.hh>
#include <G4Box.hh>
#include <G4Material.hh>
#include <G4PVPlacement.hh>
#include <G4NistManager.hh>

#include "PrimaryGeneratorAction.hh"

class DetectorConstruction : public G4VUserDetectorConstruction {
public:
    DetectorConstruction(PrimaryGeneratorAction* genAction);
    virtual ~DetectorConstruction();
    virtual G4VPhysicalVolume* Construct();
    virtual void ConstructSDandField();

    G4int GetNx() const { return fNVoxX; }
    G4int GetNy() const { return fNVoxY; }
    G4int GetNz() const { return fNVoxZ; }
    G4double GetVoxelMass() const { return fVoxelMass; }


private:
    G4LogicalVolume* fLogicPhantom;
    G4LogicalVolume* fLogicSlice;
    G4LogicalVolume* fLogicVoxel;

    G4double fPhantomSize;

    G4int fNVoxX;
    G4int fNVoxY;
    G4int fNVoxZ;

    G4double fVoxelMass;

    PrimaryGeneratorAction* fGenAction;
};

#endif // DETECTOR_CONSTRUCTION_HH
