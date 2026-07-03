#include "G4MTRunManager.hh"
#include "G4RunManager.hh"
#include "G4UIExecutive.hh"
#include "G4UImanager.hh"
#include "G4VisExecutive.hh"
#include "G4VisManager.hh"

#include "DetectorConstruction.hh"
#include "PrimaryGeneratorAction.hh"
#include "physics.hh"
#include "MyActionInitialization.hh"

int main(int argc, char** argv) {

#ifdef G4MULTITHREADED
    auto* runManager = new G4MTRunManager();
    runManager->SetNumberOfThreads(G4Threading::G4GetNumberOfCores());
    G4cout << "⚙️ Ejecutando en modo multihilo con " << G4Threading::G4GetNumberOfCores() << " hilos.\n" << G4endl;
#else
    auto* runManager = new G4RunManager();
    G4cout << "⚙️ Ejecutando en modo de un solo hilo.\n" << G4endl;
#endif

    // 1. Física
    runManager->SetUserInitialization(new MyPhysicsList());
    // 2. Generador de partículas
    auto* genAction = new PrimaryGeneratorAction();

    // 3. Geometría
    auto* detector = new DetectorConstruction(genAction);
    runManager->SetUserInitialization(detector);

    // 4. Inicialización de acciones
    runManager->SetUserInitialization(
        new MyActionInitialization(
            genAction,
            detector->GetNx(),
            detector->GetNy(),
            detector->GetNz(),
            detector->GetVoxelMass()
        )
    );

    // 5. Inicializar el Gestor de Visualización (UNA SOLA VEZ)
    G4VisManager* visManager = new G4VisExecutive();
    visManager->Initialize();

    // 6. Obtener puntero al Gestor de UI
    G4UImanager* UImanager = G4UImanager::GetUIpointer();

    // 7. Decidir entre modo BATCH o INTERACTIVO
    if (argc == 2) {
        // --- MODO BATCH ---
        // Se ejecuta una macro desde la línea de comandos
        G4String macroFile = argv[1];
        UImanager->ApplyCommand("/control/execute " + macroFile);
    } else {
        // --- MODO INTERACTIVO ---
        // Se crea la interfaz de usuario para la ventana gráfica
        auto* ui = new G4UIExecutive(argc, argv);
        // Se puede ejecutar una macro de visualización inicial
        //UImanager->ApplyCommand("/control/execute init_vis.mac");
        ui->SessionStart(); // Inicia la sesión interactiva

        // Se limpia la memoria de la UI al cerrar la ventana
        delete ui;
    }

    // 8. Limpiar la memoria al final de la ejecución
    delete visManager;
    delete runManager;

    return 0;
}