extends Node

var music_player: AudioStreamPlayer

func _init() -> void:
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    music_player.stream = load("res://assets/Castle Cards Theme 1.mp3")
    if music_player.stream:
        music_player.bus = "Music"
        music_player.play()
        print("MusicPlayer: Playing music: ", music_player.stream.resource_path)
    else:
        push_error("MusicPlayer: Could not load music file!")

func _ensure_music_bus_exists() -> void:
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index == -1:
        AudioServer.add_bus()
        bus_index = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(bus_index, "Music")

func set_volume(value: float) -> void:
    _ensure_music_bus_exists()
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index != -1:
        # Convert linear [0, 1] to decibels
        var db = linear_to_db(value)
        AudioServer.set_bus_volume_db(bus_index, db)
        # If volume is 0 (value = 0), mute it completely
        AudioServer.set_bus_mute(bus_index, value <= 0)
