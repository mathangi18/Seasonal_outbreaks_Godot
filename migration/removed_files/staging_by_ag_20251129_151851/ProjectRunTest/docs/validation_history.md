# Validation history — Seasonal_outbreaks_Godot

*(Auto-seeded with known issues & fixes. Use tools/run_and_log.ps1 to append future failures automatically.)*

## 1) Parse Error — OS.get_unix_time() / OS.get_ticks_msec() missing
**Symptoms:** Parse Error: Static function "get_unix_time()" not found (script failed to parse)
**Fix:** Avoid using non-portable static calls in top-level code. Use no-OS fallback, or get_tree().process_frame ticks. Replace with simple frame-based timing or avoid OS calls entirely in the script header.

## 2) Parse Error — nested / inner function not allowed
**Symptoms:** Parse Error: Standalone lambdas cannot be accessed. Consider assigning it to a variable.
**Fix:** Do not declare nested functions / lambdas inside unc _ready() in this style. Use local variables or compute inline.

## 3) Popup: "Can't load the script ... as it doesn't inherit from SceneTree or MainLoop"
**Symptoms:** GUI popup when running via --script (script attached extends Node but --script expects MainLoop/SceneTree or an attached scene).
**Fix:** Either:
- Run Godot with a scene that has a root Node whose script extends Node (use a .tscn with root Node and attach the script), or
- Make the script extend MainLoop/SceneTree when you intend to run it as a standalone main loop via --script.
Recommendation: For headless validators, attach the validator script to a small .tscn root Node and call --headless --path . -s res://misc/validator.tscn (or use a wrapper that does the equivalent).

---

*File seeded on 2025-11-23 02:09:43Z*
