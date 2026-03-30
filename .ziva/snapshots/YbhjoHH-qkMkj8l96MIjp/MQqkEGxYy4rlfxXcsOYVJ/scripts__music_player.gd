extends Node

var music_player: AudioStreamPlayer
var _is_playing: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    
    _ensure_music_bus_exists()
    
    var stream = load("res://assets/Castle Cards Theme 1.mp3")
    if stream:
        music_player.stream = stream
        if music_player.stream is AudioStreamMP3:
            music_player.stream.loop = true
        elif music_player.stream is AudioStreamOggVorbis:
            music_player.stream.loop = true
        elif music_player.stream is AudioStreamWAV:
            music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
            
        music_player.bus = "Music"
        
        # Initial sync with GameState
        var gs = get_node_or_null("/root/GameState")
        if gs and "music_volume" in gs:
            set_volume(gs.music_volume)
        
        _start_playing()
    else:
        push_error("MusicPlayer: Could not load music file!")

func _start_playing() -> void:
    music_player.play()
    _is_playing = true
    print("MusicPlayer: Play() called. Playing status: ", music_player.playing)
    
    # Check if we are on Web and might need interaction
    if OS.get_name() == "Web" and not music_player.playing:
        print("MusicPlayer: Detected Web platform. Audio might be blocked until interaction.")

func _input(event: InputEvent) -> void:
    # On Web, we often need a user gesture to start audio
    if OS.get_name() == "Web":
        if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
            if not music_player.playing:
                print("MusicPlayer: Resuming audio on user interaction...")
                music_player.play()

func _ensure_music_bus_exists() -> void:
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index == -1:
        AudioServer.add_bus()
        bus_index = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(bus_index, "Music")
        AudioServer.set_bus_send(bus_index, "Master")
        print("MusicPlayer: Created 'Music' bus")
    
    # Ensure Master bus is audible
    var master_index = AudioServer.get_bus_index("Master")
    AudioServer.set_bus_mute(master_index, false)
    if AudioServer.get_bus_volume_db(master_index) < -40:
        AudioServer.set_bus_volume_db(master_index, 0)
    
    # Ensure Music bus is unmuted (it might have been muted in a previous session/save)
    AudioServer.set_bus_mute(bus_index, false)

func set_volume(value: float) -> void:
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index != -1:
        var db = linear_to_db(max(0.0001, value))
        AudioServer.set_bus_volume_db(bus_index, db)
        AudioServer.set_bus_mute(bus_index, value <= 0)
        print("MusicPlayer: Volume set to ", value, " (", db, " dB)")

