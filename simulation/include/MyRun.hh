#ifndef MYRUN_HH
#define MYRUN_HH

#include <map>
#include <vector>
#include <G4Run.hh>
#include <G4String.hh>

class MyRun : public G4Run {
public:
    MyRun();
    virtual ~MyRun();

    virtual void Merge(const G4Run* run) override;

    void AddEdep(G4int ix, G4int iy, G4int iz, G4double edep, const G4String& particleName, G4bool isPrimary);

    void SetVoxelDimensions(G4int nx, G4int ny, G4int nz);
    void InitializeMaps();

    const std::vector<std::vector<std::vector<G4double>>>& GetTotalEdep() const;
    const std::vector<std::vector<std::vector<G4double>>>& GetPrimaryEdep() const;
    const std::map<G4String, std::vector<std::vector<std::vector<G4double>>>>& GetSecondaryEdep() const;

    void AddPrimaryEdep(G4int iz, G4int iy, G4int ix, G4double edep);
    void AddSecondaryEdep(G4int iz, G4int iy, G4int ix, G4double edep, const G4String& pname);
    void AddTotalEdep(G4int iz, G4int iy, G4int ix, G4double edep);

    bool IsValidIndex(int ix, int iy, int iz) const;

private:
    G4int fNx, fNy, fNz;
    std::vector<std::vector<std::vector<G4double>>> fEdepTotal;
    std::vector<std::vector<std::vector<G4double>>> fEdepPrimary;
    std::map<G4String, std::vector<std::vector<std::vector<G4double>>>> fEdepSecondary;
};

#endif
