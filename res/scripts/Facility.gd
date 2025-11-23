extends Area2D
class_name Facility

@export var capacity: int = 5
@export var service_rate: int = 1
@export var infection_control_factor: float = 0.3

var occupants: Array = []
var queue: Array = []

signal facility_overloaded
signal patient_admitted(patient_id)

func _ready():
    collision_layer = 4
    update_label()

func _process(_delta):
    update_label()

func admit(patient: Patient) -> bool:
    if occupants.size() < capacity:
        occupants.append(patient)
        patient.hospitalize()
        update_label()
        patient_admitted.emit(patient.get_instance_id())
        return true
    else:
        enqueue(patient)
        return false

func enqueue(patient: Patient):
    if not queue.has(patient):
        queue.append(patient)
        update_label()
        if queue.size() > capacity * 2:
            facility_overloaded.emit()

func tick_service():
    # Discharge logic
    var to_remove = []
    for p in occupants:
        if randf() < 0.1:
            to_remove.append(p)
    
    for p in to_remove:
        occupants.erase(p)
        p.state = Patient.State.RECOVERED
        p.visible = true
        p.position = position + Vector2(50, 50)
    
    # Admit from queue
    while occupants.size() < capacity and queue.size() > 0:
        var p = queue.pop_front()
        occupants.append(p)
        p.hospitalize()
    
    update_label()

func update_label():
    var label = $Label
    if label:
        label.text = "HOSPITAL\nOcc: %d/%d\nQ: %d" % [occupants.size(), capacity, queue.size()]
