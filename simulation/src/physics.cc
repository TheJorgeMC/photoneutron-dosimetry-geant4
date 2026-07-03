#include "physics.hh"

#include <G4EmStandardPhysics.hh>   // EM estándar
//#include <G4DecayPhysics.hh>                // Decaimientos
#include <G4HadronElasticPhysics.hh>        // Hadrónica elástica
#include <G4HadronPhysicsQGSP_BIC_HP.hh>    // Hadrónica inelástica + HP
//#include <G4IonPhysics.hh>                  // Física de iones
//#include <G4StoppingPhysics.hh>             // Captura/aniquilación
#include <G4EmExtraPhysics.hh>              // EM extra (gamma-nuclear, etc.)

#include <G4SystemOfUnits.hh>   // para microsecond

MyPhysicsList::MyPhysicsList() {
    // --- Electromagnética estándar ---
    RegisterPhysics(new G4EmStandardPhysics()); // Necesaria para fotones, e−, e+, hadrones

    // --- Electromagnética extra ---
    auto emx = new G4EmExtraPhysics(1);
    emx->GammaNuclear(true);    // ✅ Mantener para fotonuclear → neutrones secundarios
    emx->MuonNuclear(false);    // ❌ No hay muones a 6–18 MeV
    emx->Synch(false);          // ❌ No hay campos B relevantes
    emx->ElectroNuclear(false); // ❌ No relevante ahora; útil con haces de e− >100 MeV
    RegisterPhysics(emx);

    // --- Decaimientos ---
    //RegisterPhysics(new G4DecayPhysics()); // ⚠️ No afecta ahora, pero útil para otras partículas

    // --- Hadrónica ---
    RegisterPhysics(new G4HadronElasticPhysics());       // ✅ Neutrones secundarios
    RegisterPhysics(new G4HadronPhysicsQGSP_BIC_HP());   // ✅ Modelo HP para neutrones

    // --- Iones ---
    //RegisterPhysics(new G4IonPhysics()); // ❌ Irrelevante ahora; ✅ útil para terapia con iones

    // --- Procesos de parada/captura ---
    //RegisterPhysics(new G4StoppingPhysics()); // ⚠️ Poco impacto ahora; útil en hadrones lentos
}

MyPhysicsList::~MyPhysicsList() {}
