extends Node2D

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
    back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
    
    # Create 12 level buttons
    for i in range(1, 13):
        var button = Button.new()
        button.text = str(i)
        button.custom_minimum_size = Vector2(80, 80)
        button.pivot_offset = Vector2(40, 40)
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        
        # Set up styles (we'll define these in the scene or code, but scene is better)
        # For now, let's just add it to the grid.
        # We'll need to set the theme_override_styles in the script or use a theme.
        # I'll create a helper to apply the style to these dynamic buttons.
        _apply_button_style(button)
        
        if i == 1:
            button.pressed.connect(_on_level_1_pressed)
        else:
            button.disabled = false # Show as clickable but do nothing? 
            # User said: "even though we only have on playable scene for now"
            # Let's just make them do nothing or show a message.
            button.pressed.connect(func(): print("Level ", i, " is not available yet."))
        
        button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
        button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
        
        grid_container.add_child(button)

func _apply_button_style(button: Button) -> void:
    var texture = load("res://assets/background.png")
    
    var style_normal = StyleBoxTexture.new()
    style_normal.texture = texture
    # No margins for the background texture button
    
    var style_hover = style_normal.duplicate()
    style_hover.modulate_color = Color(1.2, 1.2, 1.2, 1)
    
    var style_pressed = style_normal.duplicate()
    style_pressed.modulate_color = Color(0.8, 0.8, 0.8, 1)
    
    button.add_theme_stylebox_override("normal", style_normal)
    button.add_theme_stylebox_override("hover", style_hover)
    button.add_theme_stylebox_override("pressed", style_pressed)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_font_size_override("font_size", 24)
    button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    button.add_theme_constant_override("outline_size", 4)

func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

func _on_level_1_pressed() -> void:
    get_tree().change_scene_to_file("res://battle_scene_1.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
