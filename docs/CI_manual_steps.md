# CI Manual Steps

If the automated CI fails or if running on a self-hosted runner without Godot:

1. **Install Godot 4.x**:
   - Download Godot 4.x headless binary.
   - Ensure it is in the PATH or specify path in `tools/run_and_log.ps1`.

2. **Run Wrapper**:
   - Powershell: `.\tools\run_and_log.ps1 -GodotExe path/to/godot`

3. **Check Logs**:
   - Review `logs/godot_log.txt` for errors.
