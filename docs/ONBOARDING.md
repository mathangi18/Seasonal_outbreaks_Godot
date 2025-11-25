# Onboarding — Quickstart (developer guide)

This guide explains how to clone the project, open it in Godot, create branches, and run the main scene.

## 1. Clone the repository
Open PowerShell:
    cd "D:\Repos"
    git clone https://github.com/mathangi18/Seasonal_outbreaks_Godot.git
    cd Seasonal_outbreaks_Godot

## 2. Create your feature branch
    git checkout -b feat/<yourname>/<topic>

## 3. Open in Godot
- Start Godot 4.5.x
- Select "Open Existing Project"
- Choose the Seasonal_outbreaks_Godot folder
- Let Godot finish importing all resources

## 4. Run the Main scene
- In the FileSystem panel, open scenes/Main.tscn
- Press F6 or the Play Scene button
- If scale looks wrong, see docs/CAMERA_AND_SCALE.md

## 5. Commit & Push
    git add -A
    git commit -m "feat: short description"
    git push origin feat/<yourname>/<topic>

