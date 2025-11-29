import os
import re
import subprocess
import sys

def check_absolute_paths():
    print("Checking for absolute paths in project.godot...")
    issues = []
    if os.path.exists("project.godot"):
        with open("project.godot", "r") as f:
            for i, line in enumerate(f, 1):
                if "file://" in line or re.search(r'[a-zA-Z]:\\', line) or re.search(r'/[a-zA-Z]+/', line):
                    # Ignore common relative paths or res://
                    if "res://" in line or line.strip().startswith(";"):
                        continue
                    # Simple heuristic for absolute paths
                    if re.search(r'([a-zA-Z]:[\\/])|(^/[a-zA-Z])', line):
                         issues.append(f"Line {i}: {line.strip()}")
    
    if issues:
        print("FAIL: Absolute paths found in project.godot:")
        for issue in issues:
            print(issue)
    else:
        print("PASS: No absolute paths found in project.godot")

def check_gdformat():
    print("\nChecking for gdformat...")
    try:
        result = subprocess.run(["gdformat", "--check", "."], capture_output=True, text=True)
        print(result.stdout)
        print(result.stderr)
        if result.returncode == 0:
            print("PASS: gdformat check passed")
        else:
            print("FAIL: gdformat issues found")
    except FileNotFoundError:
        print("WARN: gdformat not found, skipping lint check")

def main():
    with open("health_check.log", "w") as log_file:
        sys.stdout = log_file
        sys.stderr = log_file
        
        print("Health Check Log")
        print("=================")
        
        check_absolute_paths()
        check_gdformat()
        
        print("\nHealth check complete.")

if __name__ == "__main__":
    main()
