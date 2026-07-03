#pragma once
#include <G4UserSteppingAction.hh>

class G4Region;
class G4Step;

class SteppingAction : public G4UserSteppingAction {
public:
  SteppingAction();
  void UserSteppingAction(const G4Step* step) override;

private:
  // Se resuelve perezosamente por nombre para evitar problemas de orden en MT
  const G4Region* fPhantomRegion = nullptr;
};
