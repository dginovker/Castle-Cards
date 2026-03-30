extends Node

var music_player: AudioStreamPlayer
var _is_playing: bool = false
var _audio_resumed: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    music_player = AudioStreamPlayer.new()
    if "playback_type" in music_player:
        music_player.set("playback_type", 1) # AudioStreamPlayer.PLAYBACK_TYPE_STREAM
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
    
    if OS.get_name() == "Web":
        print("MusicPlayer: Web platform detected. Waiting for user interaction to resume audio...")

func _input(event: InputEvent) -> void:
    # On Web, we MUST have a user gesture to resume the AudioContext
    if OS.get_name() == "Web" and not _audio_resumed:
        if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
            _resume_web_audio()

func _resume_web_audio() -> void:
    _audio_resumed = true
    AudioServer.set_bus_mute(0, false)

    # Explicitly resume the browser's AudioContext via JavaScript.
    # Godot's engine is supposed to do this on user gesture, but it's unreliable
    # in iframe contexts like itch.io.
    JavaScriptBridge.eval("""
        (function() {
            var dominated = typeof GodotAudio !== 'undefined' && GodotAudio.ctx;
            if (dominated) {
                GodotAudio.ctx.resume();
            }
        })();
    """)

    # Restart playback to force the buffer to fill with the now-resumed AudioContext.
    var current_pos = music_player.get_playback_position()
    music_player.stop()
    music_player.play(current_pos)

    print("MusicPlayer: Web Audio context resumed via JavaScriptBridge.")

func _ensure_music_bus_exists() -> void:
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index == -1:
        AudioServer.add_bus()
        bus_index = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(bus_index, "Music")
        AudioServer.set_bus_send(bus_index, "Master")
        print("MusicPlayer: Created 'Music' bus")
    
    # Force Master bus to be audible
    var master_index = AudioServer.get_bus_index("Master")
    AudioServer.set_bus_mute(master_index, false)
    if AudioServer.get_bus_volume_db(master_index) < -40:
        AudioServer.set_bus_volume_db(master_index, 0)
    
    # Ensure Music bus is unmuted
    AudioServer.set_bus_mute(bus_index, false)

func set_volume(value: float) -> void:
    var bus_index = AudioServer.get_bus_index("Music")
    if bus_index != -1:
        var db = linear_to_db(max(0.0001, value))
        AudioServer.set_bus_volume_db(bus_index, db)
        AudioServer.set_bus_mute(bus_index, value <= 0)
        print("MusicPlayer: Volume set to ", value, " (", db, " dB)")

