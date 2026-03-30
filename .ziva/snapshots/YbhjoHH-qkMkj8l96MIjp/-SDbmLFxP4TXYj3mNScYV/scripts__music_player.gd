extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    
    _ensure_music_bus_exists()
    
    music_player.stream = load("res://assets/Castle Cards Theme 1.mp3")
    if music_player.stream:
        # Set loop property based on the stream type
        if music_player.stream is AudioStreamMP3:
            music_player.stream.loop = true
        elif music_player.stream is AudioStreamOggVorbis:
            music_player.stream.loop = true
        elif music_player.stream is AudioStreamWAV:
            music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
            
        music_player.bus = "Music"
        music_player.play()
        print("MusicPlayer: Playing music: ", music_player.stream.resource_path)
        
        # Sync with GameState volume if it already exists
        var gs = get_node_or_null("/root/GameState")
        if gs and "music_volume" in gs:
            print("MusicPlayer: Syncing volume from GameState: ", gs.music_volume)
            set_volume(gs.music_volume)
    else:
        push_error("MusicPlayer: Could not load music file!")

func _ensure_music_bus_exists() -> void:
    if AudioServer.get_bus_index("Music") == -1:
        AudioServer.add_bus()
        var bus_index = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(bus_index, "Music")
        # Connect to Master bus
        AudioServer.set_bus_send(bus_index, "Master")
        print("MusicPlayer: Created 'Music' bus")
    
    # Ensure Master bus is audible
    var master_index = AudioServer.get_bus_index("Master")
    # Always ensure it's not muted and has volume
    AudioServer.set_bus_mute(master_index, false)
    if AudioServer.get_bus_volume_db(master_index) < -40:
        AudioServer.set_bus_volume_db(master_index, 0)
        print("MusicPlayer: Reset Master bus volume to 0dB")
    print("MusicPlayer: Master bus unmuted")

func set_volume(value: float) -> void:
    _ensure_music_bus_exists()
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index != -1:
        # Convert linear [0, 1] to decibels
        var db = linear_to_db(value)
        AudioServer.set_bus_volume_db(bus_index, db)
        # If volume is 0 (value = 0), mute it completely
        AudioServer.set_bus_mute(bus_index, value <= 0)
        print("MusicPlayer: Volume set to ", value, " (", db, " dB)")
