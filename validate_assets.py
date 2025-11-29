import os
import sys

REQUIRED_ASSETS = {
    "assets/sprites/patient_placeholder.png": {"max_size": 51200, "ext": ".png"},
    "assets/sprites/icon_hud.svg": {"max_size": 20480, "ext": ".svg"},
    "assets/sprites/state_icons.png": {"max_size": 102400, "ext": ".png"},
    "assets/sounds/infect.ogg": {"max_size": 153600, "ext": ".ogg"}
}

def validate_assets():
    os.makedirs("assets/sprites", exist_ok=True)
    os.makedirs("assets/sounds", exist_ok=True)
    
    missing = []
    invalid = []
    
    for path, reqs in REQUIRED_ASSETS.items():
        if not os.path.exists(path):
            missing.append(path)
            continue
            
        size = os.path.getsize(path)
        if size > reqs["max_size"]:
            invalid.append(f"{path}: Size {size} > {reqs['max_size']}")
            
        if not path.endswith(reqs["ext"]):
            invalid.append(f"{path}: Invalid extension")
            
    if missing:
        print("MISSING ASSETS:")
        for m in missing:
            print(m)
            
    if invalid:
        print("INVALID ASSETS:")
        for i in invalid:
            print(i)
            
    if not missing and not invalid:
        print("ALL ASSETS VALID")

if __name__ == "__main__":
    validate_assets()
