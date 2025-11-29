import os
import json

REQUIRED_FILES = [
    "project.godot",
    "scenes/Main.tscn",
    "scenes/Simulation.tscn",
    "scenes/Patient.tscn",
    "scenes/Facility.tscn",
    "scenes/HUD.tscn",
    "scripts/Main.gd",
    "scripts/SimulationEngine.gd",
    "scripts/Patient.gd",
    "scripts/Facility.gd",
    "scripts/HUD.gd",
    "scripts/scale_utils.gd",
    "scripts/logger.gd",
    "assets/patient_placeholder.png",
    "logs/sample_sim_log.csv",
    "README.md",
    "run_instructions.md",
    "quick_test.md"
]

def validate():
    summary = {}
    all_present = True
    for file_path in REQUIRED_FILES:
        present = os.path.exists(file_path)
        summary[file_path] = present
        if not present:
            all_present = False
            print(f"MISSING: {file_path}")
    
    with open("validation_summary.json", "w") as f:
        json.dump(summary, f, indent=2)
    
    print("Validation summary written to validation_summary.json")
    if not all_present:
        exit(1)

if __name__ == "__main__":
    validate()
