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
        
    # Git diff names (moved files in last commit)
    # We just committed, so we check HEAD
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
- Replaced absolute paths in project files.
- Moved noisy files to migration staging.
- Ran static health checks.

Validation:
- See migration/validation_summary.json
- See migration/absolute_path_replacements.json

Manual Actions Required:
1. Review migration/absolute_path_suspects.json for ambiguous paths.
2. Verify assets in res://assets/ (some were missing in previous checks).
3. Run Godot smoke test manually (CLI was not available).
"""
    pr_file = os.path.join(MIGRATION_DIR, "pr_request_draft.txt")
    with open(pr_file, "w") as f:
        f.write(pr_content)
        
    # Final JSON
    final_json = {
        "branch": run_cmd("git branch --show-current"),
        "head_commit": run_cmd("git rev-parse HEAD"),
        "moved_files": [line.split('\t')[1] for line in git_diff.splitlines() if line.startswith('R') or line.startswith('A')], # Approximation
        "validation_summary": "migration/validation_summary.json",
        "replacements": "migration/absolute_path_replacements.json",
        "suspects": "migration/absolute_path_suspects.json",
        "git_status": status_file,
        "commit_log": log_file,
        "pr_request": pr_file,
        "exit_code": 0
    }
    
    print(json.dumps(final_json))

if __name__ == "__main__":
    generate_reports()
