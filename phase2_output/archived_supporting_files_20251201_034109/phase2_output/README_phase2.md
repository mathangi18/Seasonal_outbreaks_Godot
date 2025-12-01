# Seasonal Outbreaks — Phase-2 Output

**Goal:** Generate PLE-safe Godot scenes from 	ools\references\FEATURES_GODOT_FULL.txt and validate assets against 	ools\phase2\assets_to_features_map.json. Keep all outputs deterministic and accessible for baby-step PowerShell orchestration.

**Repo:** D:\Repos\Seasonal_outbreaks_Godot  
**Branch:** dev/phase-2

**Paths referenced:**
- Feature spec (in-repo): tools\references\FEATURES_GODOT_FULL.txt
- Assets root: D:\seasonal_outbreak_assets
- Assets map: tools\phase2\assets_to_features_map.json

**Phase-2 Output layout (this directory):**
- scenes/              -> final, PLE-safe .tscn files (ready to commit)
- generated_scenes/    -> generator placeholders / intermediate .tscn
- validators/          -> validator scripts & helpers
- logs/                -> run logs (deterministic)
- reports/             -> JSON/CSV validation reports

**Next deterministic baby-step (example):**
1) Generate deterministic placeholders from FEATURES_GODOT_FULL: run the script we will create 	ools\phase2\create_phase2_placeholders.ps1
2) Run asset validator: powershell -File tools\phase2\asset_validator.ps1 -AssetsDir "D:\seasonal_outbreak_assets" -AssetsMap "tools\phase2\assets_to_features_map.json"

