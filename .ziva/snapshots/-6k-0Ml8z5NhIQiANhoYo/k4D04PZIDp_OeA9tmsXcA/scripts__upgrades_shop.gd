extends Node2D

@onready var archer_button: Button = %ArcherButton
@onready var drummer_button: Button = %DrummerButton
@onready var cannon_button: Button = %CannonButton
@onready var tree_growth_button: Button = %TreeGrowthButton
@onready var back_button: Button = %BackButton

const UPGRADES = {
    "archer": {
        "name": "Archer",
        "cost": 8,
        "icon": "res://assets/units/archer/archer-walking-0.png",
    },
    "drummer": {
        "name": "Drummer",
        "cost": 15,
        "icon": "res://assets/units/drummer/drumming.png",
    },
    "cannon": {
        "name": "Cannon",
        "cost": 30,
        "icon": "res://assets/units/cannon/cannon-idle.png",
    },
    "tree_growth": {
        "name": "Tree Growth",
        "icon": "res://assets/tree.png",
    }
}

func _ready() -> void:
    _setup_square_button(archer_button, "archer")
    _setup_square_button(drummer_button, "drummer")
    _setup_square_button(cannon_button, "cannon")
    _setup_square_button(tree_growth_button, "tree_growth")
    
    archer_button.pressed.connect(func(): _buy_upgrade("archer"))
    drummer_button.pressed.connect(func(): _buy_upgrade("drummer"))
    cannon_button.pressed.connect(func(): _buy_upgrade("cannon"))
    tree_growth_button.pressed.connect(_on_tree_growth_pressed)
    back_button.pressed.connect(_on_back_pressed)
    
    GameState.trees_changed.connect(_on_trees_changed)
    update_ui()

func _setup_square_button(btn: Button, type: String) -> void:
    var info = UPGRADES[type]
    
    # Apply square style similar to level select
    var bg_texture = load("res://assets/background.png")
    var style_normal = StyleBoxTexture.new()
    style_normal.texture = bg_texture
    
    var style_hover = style_normal.duplicate()
    style_hover.modulate_color = Color(1.2, 1.2, 1.2, 1)
    
    var style_pressed = style_normal.duplicate()
    style_pressed.modulate_color = Color(0.8, 0.8, 0.8, 1)
    
    var style_disabled = style_normal.duplicate()
    style_disabled.modulate_color = Color(0.5, 0.5, 0.5, 1)
    
    btn.add_theme_stylebox_override("normal", style_normal)
    btn.add_theme_stylebox_override("hover", style_hover)
    btn.add_theme_stylebox_override("pressed", style_pressed)
    btn.add_theme_stylebox_override("disabled", style_disabled)
    btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    
    # Internal Layout
    var margin = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    btn.add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    margin.add_child(vbox)
    
    # Name Label
    var name_label = Label.new()
    name_label.name = "NameLabel"
    name_label.text = info.name
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 18)
    name_label.add_theme_color_override("font_outline_color", Color.BLACK)
    name_label.add_theme_constant_override("outline_size", 4)
    vbox.add_child(name_label)
    
    # Icon
    var icon_rect = TextureRect.new()
    icon_rect.name = "IconRect"
    icon_rect.texture = load(info.icon)
    icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_rect.custom_minimum_size = Vector2(64, 64)
    icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(icon_rect)
    
    # Cost Container
    var cost_hbox = HBoxContainer.new()
    cost_hbox.name = "CostHBox"
    cost_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_child(cost_hbox)
    
    var cost_label = Label.new()
    cost_label.name = "CostLabel"
    cost_label.add_theme_font_size_override("font_size", 18)
    cost_label.add_theme_color_override("font_outline_color", Color.BLACK)
    cost_label.add_theme_constant_override("outline_size", 4)
    cost_hbox.add_child(cost_label)
    
    var tree_icon = TextureRect.new()
    tree_icon.texture = load("res://assets/tree.png")
    tree_icon.custom_minimum_size = Vector2(20, 20)
    tree_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tree_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    cost_hbox.add_child(tree_icon)
    
    # Black outline like level select
    var outline = Panel.new()
    outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var outline_style = StyleBoxFlat.new()
    outline_style.draw_center = false
    outline_style.border_width_left = 4
    outline_style.border_width_top = 4
    outline_style.border_width_right = 4
    outline_style.border_width_bottom = 4
    outline_style.border_color = Color.BLACK
    outline.add_theme_stylebox_override("panel", outline_style)
    btn.add_child(outline)
    
    btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
    btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))

func _on_trees_changed(_new_count: int) -> void:
    update_ui()

func update_ui() -> void:
    _update_unit_button(archer_button, "archer")
    _update_unit_button(drummer_button, "drummer")
    _update_unit_button(cannon_button, "cannon")
    _update_tree_growth_button()

func _update_unit_button(btn: Button, type: String) -> void:
    var info = UPGRADES[type]
    var cost_hbox = btn.find_child("CostHBox")
    var cost_label = btn.find_child("CostLabel")
    var name_label = btn.find_child("NameLabel")
    
    if GameState.is_unit_unlocked(type):
        name_label.text = "%s\n(Unlocked)" % info.name
        btn.disabled = true
        cost_hbox.visible = false
    else:
        name_label.text = info.name
        cost_label.text = str(info.cost)
        btn.disabled = GameState.trees < info.cost
        cost_hbox.visible = true

func _update_tree_growth_button() -> void:
    var is_lvl4_beaten = GameState.is_level_beaten("level_4")
    var cost = GameState.get_tree_growth_upgrade_cost()
    var cost_hbox = tree_growth_button.find_child("CostHBox")
    var cost_label = tree_growth_button.find_child("CostLabel")
    var name_label = tree_growth_button.find_child("NameLabel")
    
    if not is_lvl4_beaten:
        name_label.text = "Tree Growth\n(Lvl 4 Req)"
        cost_hbox.visible = false
        tree_growth_button.disabled = true
    else:
        name_label.text = "Tree Growth\n(Lvl %d)" % GameState.tree_growth_upgrades
        cost_label.text = str(cost)
        cost_hbox.visible = true
        tree_growth_button.disabled = GameState.trees < cost

func _buy_upgrade(type: String) -> void:
    var info = UPGRADES[type]
    if GameState.unlock_unit(type, info.cost):
        update_ui()

func _on_tree_growth_pressed() -> void:
    if GameState.purchase_tree_growth_upgrade():
        update_ui()

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_button_mouse_entered(button: Button) -> void:
    if button.disabled: return
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
