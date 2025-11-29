import os
import shutil
import datetime
import glob
import json
import subprocess

TIMESTAMP = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
MIGRATION_DIR = "migration"
STAGING_DIR = os.path.join(MIGRATION_DIR, f"removed_files/staging_by_ag_{TIMESTAMP}")
VALIDATION_SUMMARY_FILE = os.path.join(MIGRATION_DIR, "validation_summary.json")

REQUIRED_FILES = [
    "project.godot",
    "scenes",
    "scripts",
    "assets",
    "README.md",
    "quick_test.md"
]

def move_noisy_files():
    os.makedirs(STAGING_DIR, exist_ok=True)
    print(f"Created staging directory: {STAGING_DIR}")

    candidates = [
        ".github",
        "addons/auto_play",
        "misc",
        "reports",
        "ProjectRunTest",
        "migration/removed_files" # Skip if same, but we are in migration/removed_files... wait.
        # The script is running from root. migration/removed_files contains our staging dir.
        # We should NOT move migration/removed_files into itself.
    ]
    
    # Handle files/dirs
    for item in os.listdir("."):
        if item in candidates or item.startswith("health_check"):
            if item == "migration": continue
            
            src = item
            dest = os.path.join(STAGING_DIR, item)
            
            print(f"Processing {src} -> {dest}")
            
            try:
                # Try git mv first
                if os.path.isdir(src):
                    # For directories, git mv might be tricky if content is mixed.
                    # Use shutil.move for simplicity as requested "if git mv fails"
                    # But user said "Use git mv where possible".
                    # We'll try subprocess git mv
                    ret = subprocess.call(["git", "mv", src, dest], stderr=subprocess.DEVNULL)
                    if ret != 0:
                         shutil.move(src, dest)
                else:
                    ret = subprocess.call(["git", "mv", src, dest], stderr=subprocess.DEVNULL)
                    if ret != 0:
                        shutil.move(src, dest)
            except Exception as e:
                print(f"Error moving {src}: {e}")

    # Logs - copy only
    if os.path.exists("logs"):
        dest_logs = os.path.join(STAGING_DIR, "logs")
        try:
            shutil.copytree("logs", dest_logs)
            print(f"Copied logs to {dest_logs}")
        except Exception as e:
            print(f"Error copying logs: {e}")

def static_checks():
    summary = {}
    for req in REQUIRED_FILES:
        summary[req] = os.path.exists(req)
    
    # Check assets
    os.makedirs("assets/sprites", exist_ok=True)
    os.makedirs("assets/sounds", exist_ok=True)
    
    with open(VALIDATION_SUMMARY_FILE, 'w') as f:
        json.dump(summary, f, indent=2)
    print("Static checks complete.")

def main():
    move_noisy_files()
    static_checks()

if __name__ == "__main__":
    main()
