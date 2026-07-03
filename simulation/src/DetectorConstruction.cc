#include "DetectorConstruction.hh"

#include <G4Box.hh>
#include <G4LogicalVolume.hh>
#include <G4NistManager.hh>
#include <G4PVPlacement.hh>
#include <G4PVReplica.hh>
#include <G4SystemOfUnits.hh>
#include <G4SDManager.hh>
#include <G4UnitsTable.hh>

#include <G4Region.hh>
#include <G4RegionStore.hh>
#include <G4UserLimits.hh>

#include "MyDoseDeposit.hh"

DetectorConstruction::DetectorConstruction(PrimaryGeneratorAction* genAction)
    : G4VUserDetectorConstruction(),
      fLogicPhantom(nullptr),
      fLogicSlice(nullptr),
      fLogicVoxel(nullptr),
      fPhantomSize(40. * cm),
      fGenAction(genAction)
{
    // --- Medidas de los voxeles ---
    const G4double voxelXY = 15.0 * mm;
    const G4double voxelZ  = 2.0 * mm;

    // Número de vóxeles para 40 cm (400 mm)
    fNVoxX = static_cast<G4int>(400.0 * mm / voxelXY + 0.5); // 100
    fNVoxY = static_cast<G4int>(400.0 * mm / voxelXY + 0.5); // 100
    fNVoxZ = static_cast<G4int>(400.0 * mm / voxelZ  + 0.5); // 400

    // Masa del vóxel (usando fPhantomSize para consistencia)
    G4double voxelSizeX = fPhantomSize / fNVoxX;
    G4double voxelSizeY = fPhantomSize / fNVoxY;
    G4double voxelSizeZ = fPhantomSize / fNVoxZ;
    G4double voxelVolume = voxelSizeX * voxelSizeY * voxelSizeZ;

    G4Material* water = G4NistManager::Instance()->FindOrBuildMaterial("G4_WATER");
    G4double density = water->GetDensity();
    fVoxelMass = density * voxelVolume;
}

DetectorConstruction::~DetectorConstruction() {}

G4VPhysicalVolume* DetectorConstruction::Construct() {
    auto nist = G4NistManager::Instance();
    G4Material* air   = nist->FindOrBuildMaterial("G4_AIR");
    G4Material* water = nist->FindOrBuildMaterial("G4_WATER");

    // --- Consistente con el ctor: 4x4x1 mm ---
    const G4double voxelXY = fPhantomSize / fNVoxX * mm;
    const G4double voxelZ  = fPhantomSize / fNVoxZ * mm;

    // Tamaño del fantoma según el número de vóxeles
    const G4double phantomSizeX = fNVoxX * voxelXY; // 100*4mm = 400 mm
    const G4double phantomSizeY = fNVoxY * voxelXY; // 400 mm
    const G4double phantomSizeZ = fNVoxZ * voxelZ;  // 400*1mm = 400 mm

    const G4double phantomHalfX = phantomSizeX / 2.0; // 20 cm
    const G4double phantomHalfY = phantomSizeY / 2.0; // 20 cm
    const G4double phantomHalfZ = phantomSizeZ / 2.0; // 20 cm

    // SSD
    G4double ssd = fGenAction ? fGenAction->GetSSD() : 100. * cm;
    if (ssd < 0.1 * mm || ssd > 5.0 * m) {
        G4cerr << "WARNING: SSD inválido (" << ssd/cm << " cm). Asignando 100 cm" << G4endl;
        ssd = 100. * cm;
    }

    // --- Mundo con margen en XY y Z ---
    const G4double marginXY = 1.0 * cm;
    const G4double marginZ  = 10.0 * cm;
    const G4double worldHalfX = phantomHalfX + marginXY;
    const G4double worldHalfY = phantomHalfY + marginXY;
    const G4double worldHalfZ = phantomHalfZ + ssd + marginZ;

    auto solidWorld = new G4Box("World", worldHalfX, worldHalfY, worldHalfZ);
    auto logicWorld = new G4LogicalVolume(solidWorld, air, "World");
    auto physWorld  = new G4PVPlacement(nullptr, {}, logicWorld, "World", nullptr, false, 0);

    // Fantoma (agua)
    auto solidPhantom = new G4Box("Phantom", phantomHalfX, phantomHalfY, phantomHalfZ);
    fLogicPhantom = new G4LogicalVolume(solidPhantom, water, "Phantom");
    new G4PVPlacement(nullptr, {}, fLogicPhantom, "Phantom", logicWorld, false, 0);

    // --- División del fantoma (fNVoxX * fNVoxY * fNVoxZ) ---
    
    // Z
    auto solidSlice = new G4Box("Slice", phantomHalfX, phantomHalfY, voxelZ / 2.0);
    fLogicSlice = new G4LogicalVolume(solidSlice, water, "Slice");
    new G4PVReplica("PhantomSlices", fLogicSlice, fLogicPhantom, kZAxis, fNVoxZ, voxelZ);

    // Y
    auto solidRow = new G4Box("Row", phantomHalfX, voxelXY / 2.0, voxelZ / 2.0);
    auto logicRow = new G4LogicalVolume(solidRow, water, "Row");
    new G4PVReplica("SliceRows", logicRow, fLogicSlice, kYAxis, fNVoxY, voxelXY);

    // X
    auto solidVoxel = new G4Box("Voxel", voxelXY / 2.0, voxelXY / 2.0, voxelZ / 2.0);
    fLogicVoxel = new G4LogicalVolume(solidVoxel, water, "Voxel");
    new G4PVReplica("Voxels", fLogicVoxel, logicRow, kXAxis, fNVoxX, voxelXY);

    // Log rápido
    G4cout << "[Phantom] " << fNVoxX << "x" << fNVoxY << "x" << fNVoxZ
           << " vox (" << voxelXY/mm << "x" << voxelXY/mm << "x" << voxelZ/mm << " mm)"
           << " -> " << phantomSizeX/cm << " x " << phantomSizeY/cm << " x " << phantomSizeZ/cm << " cm^3\n";
    G4cout << "[World] half " << worldHalfX/cm << " x " << worldHalfY/cm << " x " << worldHalfZ/cm << " cm\n";

    return physWorld;
}

void DetectorConstruction::ConstructSDandField() {
    auto sdManager = G4SDManager::GetSDMpointer();
    auto detector = new MyDoseDeposit(fNVoxX, fNVoxY, fNVoxZ);

    sdManager->AddNewDetector(detector);
    fLogicVoxel->SetSensitiveDetector(detector);

    // Solo salida de verificación
    G4double voxelSizeX = fPhantomSize / fNVoxX;
    G4double voxelSizeY = fPhantomSize / fNVoxY;
    G4double voxelSizeZ = fPhantomSize / fNVoxZ;
    G4double voxelVolume = voxelSizeX * voxelSizeY * voxelSizeZ;
    G4Material* water = G4NistManager::Instance()->FindOrBuildMaterial("G4_WATER");
    G4double density = water->GetDensity();

    G4cout << "Tamaño del vóxel: " 
           << G4BestUnit(voxelSizeX, "Length") << " x "
           << G4BestUnit(voxelSizeY, "Length") << " x "
           << G4BestUnit(voxelSizeZ, "Length") << G4endl;
    G4cout << "Volumen del vóxel: " << G4BestUnit(voxelVolume, "Volume") << G4endl;
    G4cout << "Densidad del material: " << G4BestUnit(density, "Volumic Mass") << G4endl;
    G4cout << "Masa del vóxel: " << G4BestUnit(fVoxelMass, "Mass") << G4endl;

}
