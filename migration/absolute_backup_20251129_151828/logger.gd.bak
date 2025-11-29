extends Node
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 8

var log_file: FileAccess
var file_path = "user://logs/sim_log.csv"

func _ready():
	# Ensure directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
		
	write_header()

func write_header():
	log_file = FileAccess.open(file_path, FileAccess.WRITE)
	if log_file:
		log_file.store_line("Tick,Susceptible,Exposed,Infectious,Recovered,Queued,Hospitalized")
		log_file.close() # Close after write to ensure save, or keep open? 
		# Better to keep open if writing frequently, but for safety/simplicity we'll append.
	else:
		print("Logger: Failed to open log file at ", file_path)

func log_counts(tick, s, e, i, r, queued, hospitalized):
	# Re-open in append mode
	log_file = FileAccess.open(file_path, FileAccess.READ_WRITE)
	if log_file:
		log_file.seek_end()
		var line = "%d,%d,%d,%d,%d,%d,%d" % [tick, s, e, i, r, queued, hospitalized]
		log_file.store_line(line)
		log_file.close()
