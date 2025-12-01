extends Node

# Audio channels
var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

# Volume settings
@export var ambient_volume: float = -10.0
@export var sfx_volume: float = 0.0
@export var music_volume: float = -5.0

# Audio resources (will be loaded if files exist)
var ambient_bg: AudioStream
var ambulance_siren: AudioStream
var patient_moan: AudioStream
var ui_pop: AudioStream
var cinematic_sting: AudioStream

func _ready():
    # Create audio players
    ambient_player = AudioStreamPlayer.new()
    sfx_player = AudioStreamPlayer.new()
    music_player = AudioStreamPlayer.new()
    
    add_child(ambient_player)
    add_child(sfx_player)
    add_child(music_player)
    
    ambient_player.volume_db = ambient_volume
    sfx_player.volume_db = sfx_volume
    music_player.volume_db = music_volume
    
    # Try to load audio files (gracefully handle missing files)
    load_audio_resources()
    
    # Start ambient loop if available
    if ambient_bg:
        ambient_player.stream = ambient_bg
        ambient_player.play()

func load_audio_resources():
    ambient_bg = try_load("res://sounds/ambient_bg.ogg")
    ambulance_siren = try_load("res://sounds/ambulance_siren.ogg")
    patient_moan = try_load("res://sounds/patient_moan.ogg")
    ui_pop = try_load("res://sounds/ui_pop.ogg")
    cinematic_sting = try_load("res://sounds/cinematic_sting.ogg")

func try_load(path: String) -> AudioStream:
    if ResourceLoader.exists(path):
        return load(path)
    return null

func play_sfx(sfx_name: String):
    var stream: AudioStream = null
    match sfx_name:
        "ambulance_siren": stream = ambulance_siren
        "patient_moan": stream = patient_moan
        "ui_pop": stream = ui_pop
        "cinematic_sting": stream = cinematic_sting
    
    if stream and sfx_player:
        sfx_player.stream = stream
        sfx_player.play()

func play_music(music_stream: AudioStream):
    if music_player and music_stream:
        music_player.stream = music_stream
        music_player.play()

func stop_music():
    if music_player:
        music_player.stop()


