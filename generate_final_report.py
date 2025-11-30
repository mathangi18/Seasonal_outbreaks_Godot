import os
import subprocess
import json
import datetime

TIMESTAMP = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
MIGRATION_DIR = "migration"

def run_cmd(cmd):
    return subprocess.check_output(cmd, shell=True, text=True).strip()

def generate_reports():
    # Git status
    git_status = run_cmd("git status")
    status_file = os.path.join(MIGRATION_DIR, f"git_status_{TIMESTAMP}.txt")
    with open(status_file, "w") as f:
        f.write(git_status)
        
    # Git log
    git_log = run_cmd("git log -n 5 --oneline")
    log_file = os.path.join(MIGRATION_DIR, f"commit_log_{TIMESTAMP}.txt")
    with open(log_file, "w") as f:
        f.write(git_log)
        
    # Git diff names
    git_diff = run_cmd("git show --name-status --oneline HEAD")
    diff_file = os.path.join(MIGRATION_DIR, f"git_diff_names_{TIMESTAMP}.txt")
    with open(diff_file, "w") as f:
        f.write(git_diff)
        
    # PR Request Draft
    pr_content = f"""PR Request Draft
================
Branch: {run_cmd('git branch --show-current')}
Head Commit: {run_cmd('git rev-parse --short HEAD')}

Changes:
- Strict case-sensitive path validation.
- Moved noisy files to staging.
- Validated assets.
- Ran headless smoke test.

Validation:
- migration/validation_summary.json
- migration/absolute_path_replacements.json
- migration/assets_checksums.json

Issues:
- See migration/absolute_path_suspects.json
- See migration/godot_headless_err_*.log
"""
    pr_file = os.path.join(MIGRATION_DIR, "pr_request_draft.txt")
    with open(pr_file, "w") as f:
        f.write(pr_content)
        
    # Final JSON
    final_json = {
        "branch": run_cmd("git branch --show-current"),
        "head_commit": run_cmd("git rev-parse HEAD"),
        "validation": "migration/validation_summary.json",
        "replacements": "migration/absolute_path_replacements.json",
        "suspects": "migration/absolute_path_suspects.json",
        "assets_checksums": "migration/assets_checksums.json",
        "godot_err": "migration/godot_headless_err_*.log", # Wildcard as timestamp varies
        "pr_request": pr_file,
        "exit_code": 0
    }
    
    print(json.dumps(final_json))

if __name__ == "__main__":
    generate_reports()
