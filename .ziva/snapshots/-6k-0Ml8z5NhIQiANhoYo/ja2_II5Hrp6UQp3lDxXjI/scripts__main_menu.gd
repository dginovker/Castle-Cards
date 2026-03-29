class_name MainMenu
extends Node2D

@onready var play_button: Button = %PlayButton
@onready var upgrades_button: Button = %UpgradesButton

func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    upgrades_button.pressed.connect(_on_upgrades_pressed)
    
    play_button.mouse_entered.connect(_on_button_mouse_entered.bind(play_button))
    play_button.mouse_exited.connect(_on_button_mouse_exited.bind(play_button))
    upgrades_button.mouse_entered.connect(_on_button_mouse_entered.bind(upgrades_button))
    upgrades_button.mouse_exited.connect(_on_button_mouse_exited.bind(upgrades_button))
    
func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

func _on_play_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_upgrades_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/upgrades_shop.tscn")
