extends Node2D

@onready var wipe_button: Button = %WipeButton
@onready var back_button: Button = %BackButton

func _ready() -> void:
    wipe_button.pressed.connect(_on_wipe_pressed)
    back_button.pressed.connect(_on_back_pressed)
    
    wipe_button.mouse_entered.connect(_on_button_mouse_entered.bind(wipe_button))
    wipe_button.mouse_exited.connect(_on_button_mouse_exited.bind(wipe_button))
    back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
    back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))

func _on_wipe_pressed() -> void:
    GameState.wipe_save()
    # Provide some visual feedback?
    # Maybe change the text temporarily
    wipe_button.text = "Save Wiped!"
    await get_tree().create_timer(1.0).timeout
    wipe_button.text = "Wipe Save"

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
