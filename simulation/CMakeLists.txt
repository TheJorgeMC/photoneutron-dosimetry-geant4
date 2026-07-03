cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(PhotoneutronDosimetry)

# Release + native optimization
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -march=native")

# Find Geant4 (with UI + Vis so the interactive visualizer works)
find_package(Geant4 REQUIRED ui_all vis_all)
include(${Geant4_USE_FILE})

# Headers live in include/
include_directories(${PROJECT_SOURCE_DIR}/include)

# Explicit source list
set(SOURCES
    src/sim.cc
    src/DetectorConstruction.cc
    src/PrimaryGeneratorAction.cc
    src/physics.cc
    src/MyRunAction.cc
    src/MyRun.cc
    src/MyDoseDeposit.cc
    src/MyActionInitialization.cc
    src/PrimaryGeneratorMessenger.cc
    src/SteppingAction.cc
)

add_executable(sim ${SOURCES})
target_link_libraries(sim ${Geant4_LIBRARIES})

# Copy macros next to the binary so "./sim macros/photon_15MeV.mac" works from
# the build directory, and copy the batch scripts there too (master.sh /
# run_photon.sh expect to run from build/, alongside ./sim).
file(GLOB MACRO_FILES "${PROJECT_SOURCE_DIR}/macros/*.mac")
file(COPY ${MACRO_FILES} DESTINATION ${PROJECT_BINARY_DIR}/macros)
file(COPY ${PROJECT_SOURCE_DIR}/scripts/master.sh
          ${PROJECT_SOURCE_DIR}/scripts/run_photon.sh
     DESTINATION ${PROJECT_BINARY_DIR}
     FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                      GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

add_custom_target(PhotoneutronDosimetry DEPENDS sim)
