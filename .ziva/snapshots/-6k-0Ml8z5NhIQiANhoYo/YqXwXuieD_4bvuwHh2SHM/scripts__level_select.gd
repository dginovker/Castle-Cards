extends Node2D

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
    back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
    
            
    # Only show Level 1, 2 and 3 for now
    # But set up for a 2x4 grid (8 buttons total)
    for i in range(1, 9):
        if i > 3:
            # We skip these for now since they don't exist
            continue
            
        var button = Button.new()
        button.text = str(i)
        button.custom_minimum_size = Vector2(160, 160) # 2x bigger (previously 80x80)
        button.pivot_offset = Vector2(80, 80)
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        
        _apply_button_style(button)
        
        # Add a black outline border
        var outline = Panel.new()
        outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        outline.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block button clicks
        
        var outline_style = StyleBoxFlat.new()
        outline_style.draw_center = false
        outline_style.border_width_left = 4
        outline_style.border_width_top = 4
        outline_style.border_width_right = 4
        outline_style.border_width_bottom = 4
        outline_style.border_color = Color(0, 0, 0, 1) # Black outline
        outline.add_theme_stylebox_override("panel", outline_style)
        
        button.add_child(outline)
        
        if i == 1:
            button.pressed.connect(_on_level_1_pressed)
        elif i == 2:
            button.pressed.connect(_on_level_2_pressed)
        elif i == 3:
            button.pressed.connect(_on_level_3_pressed)
        
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
    button.add_theme_font_size_override("font_size", 48) # 2x bigger (previously 24)
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

func _on_level_2_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_2.tscn")

func _on_level_3_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_3.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
