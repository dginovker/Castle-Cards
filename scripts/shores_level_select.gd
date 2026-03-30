extends Node2D

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton
@onready var no_levels_label: Label = $UI/CenterContainer/VBoxContainer/NoLevelsLabel as Label

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
    back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
    _populate_level_buttons()

func _populate_level_buttons() -> void:
    for child: Node in grid_container.get_children():
        child.queue_free()

    var gs: Node = get_node_or_null("/root/GameState")
    
    # Level 5
    var l5_unlocked: bool = gs and gs.is_level_beaten("level_4")
    _create_level_button("5", "Play Shores level 5", l5_unlocked, "Requires beating forest level 4", _on_level_5_pressed)
    
    # Level 6
    var l6_unlocked: bool = gs and gs.is_level_beaten("shores_level_5")
    _create_level_button("6", "Play Shores level 6", l6_unlocked, "Requires beating shores level 5", _on_level_6_pressed)

    # Level 7
    var l7_unlocked: bool = gs and gs.is_level_beaten("shores_level_6")
    _create_level_button("7", "Play Shores level 7", l7_unlocked, "Requires beating shores level 6", _on_level_7_pressed)

    # Level 8
    var l8_unlocked: bool = gs and gs.is_level_beaten("shores_level_7")
    _create_level_button("8", "Play Shores level 8", l8_unlocked, "Requires beating shores level 7", _on_level_8_pressed)

    no_levels_label.visible = false

func _create_level_button(lvl_text: String, tooltip: String, unlocked: bool, locked_tooltip: String, press_handler: Callable) -> void:
    var button := Button.new()
    button.text = lvl_text
    button.custom_minimum_size = Vector2(160, 160)
    button.pivot_offset = Vector2(80, 80)

    _apply_button_style(button)

    if unlocked:
        button.tooltip_text = tooltip
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        button.pressed.connect(press_handler)
    else:
        button.tooltip_text = locked_tooltip
        button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
        button.disabled = true

    button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
    button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

    grid_container.add_child(button)

func _on_level_6_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_6.tscn")

func _on_level_7_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_7.tscn")

func _on_level_8_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_8.tscn")

func _apply_button_style(button: Button) -> void:
    var texture: Texture2D = load("res://assets/shores_background_and_ground.png")

    var style_normal := StyleBoxTexture.new()
    style_normal.texture = texture

    var style_hover: StyleBoxTexture = style_normal.duplicate()
    style_hover.modulate_color = Color(1.2, 1.2, 1.2, 1)

    var style_pressed: StyleBoxTexture = style_normal.duplicate()
    style_pressed.modulate_color = Color(0.8, 0.8, 0.8, 1)

    var style_disabled: StyleBoxTexture = style_normal.duplicate()
    style_disabled.modulate_color = Color(0.4, 0.4, 0.4, 1.0)

    button.add_theme_stylebox_override("normal", style_normal)
    button.add_theme_stylebox_override("hover", style_hover)
    button.add_theme_stylebox_override("pressed", style_pressed)
    button.add_theme_stylebox_override("disabled", style_disabled)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_font_size_override("font_size", 48)
    button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1))
    button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    button.add_theme_constant_override("outline_size", 4)

func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

func _on_level_5_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_5.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/level_select.tscn")
