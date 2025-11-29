import os
import re
import json
import shutil
import datetime

TIMESTAMP = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
MIGRATION_DIR = "migration"
BACKUP_DIR = os.path.join(MIGRATION_DIR, f"absolute_backup_{TIMESTAMP}")
SUSPECTS_FILE = os.path.join(MIGRATION_DIR, "absolute_path_suspects.json")
REPLACEMENTS_FILE = os.path.join(MIGRATION_DIR, "absolute_path_replacements.json")

# Regex for absolute paths (Windows & Unix)
# Exclude res:// and user://
ABS_PATH_REGEX = re.compile(r'(?<!res://)(?<!user://)(?:[a-zA-Z]:[\\/]|(?<!\.)/[a-zA-Z])[\w\-. /\\:]+')

def is_relevant_file(path):
    if "migration" in path or ".git" in path or "ProjectRunTest" in path:
        return False
    ext = os.path.splitext(path)[1]
    return ext in ['.tscn', '.gd', '.tres', '.import'] or os.path.basename(path) == 'project.godot'

def get_replacement(match_str):
    # Simple heuristic: if it contains "assets", map to res://assets/...
    # If it contains "scripts", map to res://scripts/...
    # If it contains "scenes", map to res://scenes/...
    
    match_str_lower = match_str.lower().replace('\\', '/')
    
    for key in ['assets', 'scripts', 'scenes', 'logs']:
        idx = match_str_lower.find(f"/{key}/")
        if idx != -1:
            return f"res:/{match_str_lower[idx:]}", "HIGH"
        
        # Try without leading slash
        idx = match_str_lower.find(f"{key}/")
        if idx != -1 and (idx == 0 or match_str_lower[idx-1] in [':', ' ']):
             return f"res://{match_str_lower[idx:]}", "HIGH"

    return None, "LOW"

def main():
    os.makedirs(BACKUP_DIR, exist_ok=True)
    
    suspects = []
    replacements = []
    
    for root, dirs, files in os.walk("."):
        # Skip hidden and migration dirs
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'migration' and d != 'ProjectRunTest']
        
        for file in files:
            file_path = os.path.join(root, file)
            if not is_relevant_file(file_path):
                continue
                
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
                continue
                
            new_content = content
            modified = False
            
            # Find matches
            for match in ABS_PATH_REGEX.finditer(content):
                full_match = match.group(0)
                # Filter out common false positives
                if len(full_match) < 3 or "remotetransform" in full_match.lower(): 
                    continue
                
                # Check if it's already a res:// path that got caught (regex should prevent this but be safe)
                start_idx = match.start()
                if start_idx >= 6 and content[start_idx-6:start_idx] == "res://":
                    continue

                replacement, confidence = get_replacement(full_match)
                
                suspect = {
                    "file": file_path,
                    "original_text": full_match,
                    "suggested_replacement": replacement,
                    "confidence": confidence
                }
                suspects.append(suspect)
                
                if confidence == "HIGH" and replacement:
                    # Perform replacement
                    # We need to be careful about overlapping matches, but regex finditer is non-overlapping
                    # We'll replace in new_content
                    new_content = new_content.replace(full_match, replacement)
                    
                    replacements.append({
                        "file": file_path,
                        "before": full_match,
                        "after": replacement
                    })
                    modified = True
            
            if modified:
                # Backup
                backup_path = os.path.join(BACKUP_DIR, file + ".bak")
                shutil.copy2(file_path, backup_path)
                
                # Write changes
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed paths in {file_path}")

    # Write reports
    with open(SUSPECTS_FILE, 'w') as f:
        json.dump(suspects, f, indent=2)
        
    with open(REPLACEMENTS_FILE, 'w') as f:
        json.dump(replacements, f, indent=2)

    print(f"Processed files. Suspects: {len(suspects)}, Replacements: {len(replacements)}")

if __name__ == "__main__":
    main()
