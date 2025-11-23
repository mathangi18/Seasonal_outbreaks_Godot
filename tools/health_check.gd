extends SceneTree
func _init():
    call_deferred('_run')
func _run():
    var scripts = [
        'res://res/scripts/SimulationEngine.gd',
        'res://res/scripts/Patient.gd',
        'res://res/scripts/Facility.gd',
        'res://res/scripts/Ambulance.gd',
        'res://res/scripts/HUD.gd'
    ]
    var ok = true
    for s in scripts:
        if not ResourceLoader.exists(s):
            print('MISSING: ', s)
            ok = false
    if ok: print('HEALTH_CHECK_OK')
    else: print('HEALTH_CHECK_FAILED')
    quit()
