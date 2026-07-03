#include "SteppingAction.hh"

#include <G4RegionStore.hh>
#include <G4Step.hh>
#include <G4Neutron.hh>
#include <G4LogicalVolume.hh>
#include <G4TouchableHistory.hh>
#include <G4VPhysicalVolume.hh>

SteppingAction::SteppingAction() : fPhantomRegion(nullptr) {}

void SteppingAction::UserSteppingAction(const G4Step* step) {
  auto* track = step->GetTrack();

  // Resolver la región del fantoma la primera vez que se necesite
  if (!fPhantomRegion) {
    fPhantomRegion = G4RegionStore::GetInstance()->GetRegion("PhantomRegion", false);
  }

  // Si no existe esa región, no hacemos nada (por seguridad)
  if (!fPhantomRegion) return;

  // Mata NEUTRONES cuando están fuera de la región del fantoma
  if (track->GetDefinition() == G4Neutron::Definition()) {
    const auto* pre = step->GetPreStepPoint();
    const auto* preVol = pre->GetTouchableHandle()->GetVolume();
    if (!preVol) return;

    const auto* reg = preVol->GetLogicalVolume()->GetRegion();
    if (reg != fPhantomRegion) {
      track->SetTrackStatus(fStopAndKill);
      return;
    }
  }
}
