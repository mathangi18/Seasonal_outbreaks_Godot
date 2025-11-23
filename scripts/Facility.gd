extends Area2D
class_name Facility

@export var capacity: int = 5
@export var service_rate: int = 1

var occupants: Array = []
var queue: Array = []

signal facility_overloaded

func _ready():
	collision_layer = 4 # Layer 3: Facility (bit 2) -> wait, layer 3 is 4
	update_label()

func admit(patient: Patient) -> bool:
	if occupants.size() < capacity:
		occupants.append(patient)
		patient.hospitalize()
		update_label()
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
	# Discharge logic (simple: 10% chance per tick to recover/leave)
	var to_remove = []
	for p in occupants:
		if randf() < 0.1:
			to_remove.append(p)
			
	for p in to_remove:
		occupants.erase(p)
		p.state = Patient.State.RECOVERED
		p.visible = true
		p.position = position + Vector2(50, 50) # Discharge near facility
		
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
