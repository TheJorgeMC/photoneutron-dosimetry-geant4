#ifndef MY_PHYSICS_LIST_HH
#define MY_PHYSICS_LIST_HH

#include <G4VModularPhysicsList.hh>

class MyPhysicsList : public G4VModularPhysicsList {
public:
    MyPhysicsList();
    virtual ~MyPhysicsList();
};

#endif
