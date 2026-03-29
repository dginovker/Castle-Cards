extends Node2D

@onready var wipe_button: Button = %WipeButton
@onready var back_button: Button = %BackButton
@onready var confirmation_popup: Control = %ConfirmationPopup
@onready var confirm_wipe_button: Button = %ConfirmWipeButton
@onready var cancel_wipe_button: Button = %CancelWipeButton
@onready var music_slider: HSlider = %MusicSlider
@onready var highest_level_label: Label = %HighestLevelLabel
@onready var wins_label: Label = %WinsLabel
@onready var losses_label: Label = %LossesLabel
@onready var win_rate_label: Label = %WinRateLabel

func _ready() -> void:
    wipe_button.pressed.connect(_on_wipe_pressed)
    back_button.pressed.connect(_on_back_pressed)
    confirm_wipe_button.pressed.connect(_on_confirm_wipe_pressed)
    cancel_wipe_button.pressed.connect(_on_cancel_wipe_pressed)
    
    music_slider.value_changed.connect(_on_music_volume_changed)
    
    var gs = get_node_or_null("/root/GameState")
    if gs:
        music_slider.value = gs.music_volume
        _refresh_stats(gs)
    
    # Hover effects for main buttons
    _setup_hover_effect(wipe_button)
    _setup_hover_effect(back_button)
    # Hover effects for popup buttons
    _setup_hover_effect(confirm_wipe_button)
    _setup_hover_effect(cancel_wipe_button)

func _setup_hover_effect(button: Button) -> void:
    button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
    button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func _on_wipe_pressed() -> void:
    confirmation_popup.visible = true

func _on_confirm_wipe_pressed() -> void:
    var gs = get_node_or_null("/root/GameState")
    if gs:
        gs.wipe_save()
        _refresh_stats(gs)
    confirmation_popup.visible = false
    # Feedback on the original wipe button
    wipe_button.text = "Save Wiped!"
    await get_tree().create_timer(1.0).timeout
    wipe_button.text = "Wipe Save"

func _refresh_stats(gs) -> void:
    if gs:
        highest_level_label.text = "Highest: " + gs.get_highest_level_beaten()
        wins_label.text = "Wins: " + str(gs.total_wins)
        losses_label.text = "Losses: " + str(gs.total_losses)
        win_rate_label.text = "Win Rate: %d%%" % int(gs.get_win_rate())

func _on_cancel_wipe_pressed() -> void:
    confirmation_popup.visible = false

func _on_music_volume_changed(value: float) -> void:
    var gs = get_node_or_null("/root/GameState")
    if gs:
        gs._on_music_volume_changed(value)

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
