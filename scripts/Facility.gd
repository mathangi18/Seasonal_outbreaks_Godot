extends Node2D
class_name Facility
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 6

@export var capacity: int = 10
@export var service_rate: int = 1

var occupants: Array = []
var queue: Array = []

signal facility_overloaded

func _ready():
	update_label()

func admit(patient) -> bool:
	if occupants.size() < capacity:
		occupants.append(patient)
		update_label()
		return true
	else:
		enqueue(patient)
		return false

func enqueue(patient):
	if not queue.has(patient):
		queue.append(patient)
		update_label()
		if queue.size() > capacity * 2: # Arbitrary overload threshold
			emit_signal("facility_overloaded")

func tick_service():
	# Discharge recovered patients or process service
	# For this simple model, we'll just remove N patients per tick if they are recovered
	# Or we can assume service rate means "chance to recover" or "speed of recovery"
	# The spec says "service_rate" but doesn't define exact mechanic.
	# Let's assume service rate = number of patients processed/discharged per tick
	
	var discharged = 0
	for i in range(min(service_rate, occupants.size())):
		# In a real sim, we'd check if they are ready to leave.
		# Here, we'll just simulate turnover for the sake of the queue.
		# But wait, patients have state. We should only discharge RECOVERED patients?
		# Or does the facility accelerate recovery?
		# Let's assume facility holds them until RECOVERED.
		pass
		
	# Check for recovered patients to discharge
	var to_remove = []
	for p in occupants:
		if p.has_method("is_infectious") and not p.is_infectious(): # Recovered or Susceptible (if wrongly admitted)
			to_remove.append(p)
	
	for p in to_remove:
		occupants.erase(p)
		discharged += 1
		
	# Admit from queue
	while occupants.size() < capacity and queue.size() > 0:
		var p = queue.pop_front()
		occupants.append(p)
		
	update_label()

func update_label():
	var label = get_node_or_null("Label")
	if label:
		label.text = "HOSPITAL\nOcc: %d/%d\nQueue: %d" % [occupants.size(), capacity, queue.size()]
