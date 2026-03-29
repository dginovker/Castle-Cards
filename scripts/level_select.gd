extends Node2D

@onready var grid_container: GridContainer = %GridContainer
@onready var back_button: Button = %BackButton
@onready var shores_button: Button = %ShoresButton

func _ready() -> void:
    back_button.pressed.connect(_on_back_pressed)
    back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
    back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
    
    # Access GameState singleton through root node to avoid identifier issues
    var gs = get_node_or_null("/root/GameState")
    var forest_complete = false
    if gs:
        forest_complete = gs.is_level_beaten("level_4")
        
    shores_button.text = "Go to Shores"
    shores_button.disabled = false # Never use disabled state to avoid auto-transparency
    
    if not forest_complete:
        # LOCKED: keep full-opacity visual (not faded), but unclickable.
        # Keep scene-defined styleboxes intact so the button doesn't look washed out.
        shores_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
        shores_button.tooltip_text = "Requires beating level 4"
        shores_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

        # Disconnect any existing pressed signal
        if shores_button.pressed.is_connected(_on_shores_pressed):
            shores_button.pressed.disconnect(_on_shores_pressed)
    else:
        # UNLOCKED LOOK: Normal bright stone button
        shores_button.modulate = Color(1, 1, 1, 1)
        shores_button.tooltip_text = "Venture to the Shores"
        shores_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        
        # Connect signal
        if not shores_button.pressed.is_connected(_on_shores_pressed):
            shores_button.pressed.connect(_on_shores_pressed)
        
        # Add hover effects
        shores_button.mouse_entered.connect(_on_button_mouse_entered.bind(shores_button))
        shores_button.mouse_exited.connect(_on_button_mouse_exited.bind(shores_button))
    
            
    # Only show Level 1, 2, 3 and 4 for now
    # But set up for a 2x4 grid (8 buttons total)
    for i in range(1, 9):
        if i > 4:
            # We skip these for now since they don't exist
            continue
            
        var button = Button.new()
        button.text = str(i)
        button.custom_minimum_size = Vector2(160, 160) # 2x bigger (previously 80x80)
        button.pivot_offset = Vector2(80, 80)
        
        # Check if level is unlocked
        var is_unlocked = true
        if i > 1:
            if gs:
                is_unlocked = gs.is_level_beaten("level_" + str(i-1))
            else:
                is_unlocked = false
        
        # Use same locking pattern as Shores button
        button.disabled = false 
        
        if not is_unlocked:
            button.tooltip_text = "Requires beating level " + str(i-1)
            button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
            button.modulate = Color(1.0, 1.0, 1.0, 1.0)
            
            # Disconnect if we have any connection (we'll connect below)
            # but actually we only connect if is_unlocked
        else:
            button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
            button.tooltip_text = "Play level " + str(i)
        
        _apply_button_style(button)
        
        # Override style for locked state if needed
        if not is_unlocked:
            var style_locked = button.get_theme_stylebox("normal").duplicate()
            if style_locked is StyleBoxTexture:
                style_locked.modulate_color = Color(0.3, 0.3, 0.3, 1.0)
            button.add_theme_stylebox_override("normal", style_locked)
            button.add_theme_stylebox_override("hover", style_locked)
            button.add_theme_stylebox_override("pressed", style_locked)
            button.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
        
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
        
        if is_unlocked:
            if i == 1:
                button.pressed.connect(_on_level_1_pressed)
            elif i == 2:
                button.pressed.connect(_on_level_2_pressed)
            elif i == 3:
                button.pressed.connect(_on_level_3_pressed)
            elif i == 4:
                button.pressed.connect(_on_level_4_pressed)
        
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
    
    var style_disabled = style_normal.duplicate()
    style_disabled.modulate_color = Color(0.4, 0.4, 0.4, 1.0) # Darker and opaque
    
    button.add_theme_stylebox_override("normal", style_normal)
    button.add_theme_stylebox_override("hover", style_hover)
    button.add_theme_stylebox_override("pressed", style_pressed)
    button.add_theme_stylebox_override("disabled", style_disabled)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.add_theme_font_size_override("font_size", 48) # 2x bigger (previously 24)
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

func _on_level_1_pressed() -> void:
    get_tree().change_scene_to_file("res://battle_scene_1.tscn")

func _on_level_2_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_2.tscn")

func _on_level_3_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_3.tscn")

func _on_level_4_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/battle_scene_4.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_shores_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/shores_level_select.tscn")
