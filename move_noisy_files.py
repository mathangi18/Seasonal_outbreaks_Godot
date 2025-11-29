import os
import shutil
import datetime
import glob

def move_files():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    staging_dir = f"migration/removed_files/staging_by_ag_{timestamp}"
    os.makedirs(staging_dir, exist_ok=True)
    print(f"Created staging directory: {staging_dir}")

    candidates = [
        ".github/workflows",
        "addons/auto_play",
        "misc",
        "reports",
        "tests",
        "tools"
    ]
    
    # Move directories
    for candidate in candidates:
        if os.path.exists(candidate):
            dest = os.path.join(staging_dir, os.path.basename(candidate))
            print(f"Moving {candidate} to {dest}")
            try:
                shutil.move(candidate, dest)
            except Exception as e:
                print(f"Error moving {candidate}: {e}")

    # Copy logs
    if os.path.exists("logs"):
        dest_logs = os.path.join(staging_dir, "logs")
        print(f"Copying logs to {dest_logs}")
        try:
            shutil.copytree("logs", dest_logs)
        except Exception as e:
            print(f"Error copying logs: {e}")

    # Move health check files
    health_check_files = glob.glob("health_check*.log") + glob.glob("health_check*.txt")
    for f in health_check_files:
        dest = os.path.join(staging_dir, os.path.basename(f))
        print(f"Moving {f} to {dest}")
        try:
            shutil.move(f, dest)
        except Exception as e:
            print(f"Error moving {f}: {e}")

if __name__ == "__main__":
    move_files()
