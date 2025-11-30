# Action Patches

This directory contains patches and remediation scripts for validation failures found in `bound_mappings_final.json`.

## Current Status

**No patches generated yet** - The validation identified 80 constraint violations, but most (69) are C02 violations for non-existent scenes, which is expected behavior at this pipeline stage.

## Manual Fixes Required

### Priority 1: C08 Violations (Case Sensitivity) - 9 assets

The following assets are referenced in mappings but not found with exact case-sensitive filenames:

1. `patient_placeholder.png`
2. `ambulance.png`
3. `facility.png`
4. `patient.png`
5. `person_walk.json (duplicate-lottie)`
6. `mixkit-sci-fi-click-900.normalized.mp3`
7. `mixkit-sick-man-coughing-2221.normalized.mp3`
8. `mixkit-slot-machine-win-alert-1931.normalized.mp3`
9. `synth-ambulance-20-79441.normalized.mp3`

**Action**: Verify these files exist on disk or remove/update the mappings.

### Priority 2: C11 Violations (res:// Paths) - 2 assets

The following assets have notes fields missing `res://` scheme:

1. `person_walk.json (duplicate-lottie)` - notes field needs `res://` prefix
2. `ui_pop.wav` - notes field needs `res://` prefix

**Action**: Edit `bound_mappings_final.json` and add `res://` prefixes to asset paths in notes fields.

## Expected C02 Violations

69 mappings reference scenes that don't exist yet. This is **expected** and will be resolved when scenes are generated in the next pipeline stage.

## How to Apply Fixes

### Manual Editing

1. Open `migration/bound_mappings_final.json`
2. Search for the affected assets listed above
3. Make the necessary corrections
4. Save the file
5. Re-run validation: `.\Validate-BoundMappings.ps1`

### Automated Patches (Future)

When automated patches are generated, they will appear here as:
- `*.diff` files - Git-style diffs showing proposed changes
- `apply_patches.ps1` - PowerShell script to apply patches with dry-run mode
- Individual patch files with descriptive names

## Safety

- All patches are non-destructive by default
- Dry-run mode available for preview
- Backup recommendations included in patch scripts
- Idempotent operations (safe to run multiple times)

## Next Steps

1. Fix C08 and C11 violations manually
2. Re-run validation to confirm fixes
3. Proceed to scene generation stage (C02 violations will be resolved)
