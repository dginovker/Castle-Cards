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
    "passive_income": {
        "name": "Passive Wood Income",
        "icon": "res://assets/tree.png",
    }
}

func _ready() -> void:
    _setup_square_button(archer_button, "archer")
    _setup_square_button(drummer_button, "drummer")
    _setup_square_button(cannon_button, "cannon")
    _setup_square_button(tree_growth_button, "passive_income")
    
    archer_button.pressed.connect(func(): _buy_upgrade("archer"))
    drummer_button.pressed.connect(func(): _buy_upgrade("drummer"))
    cannon_button.pressed.connect(func(): _buy_upgrade("cannon"))
    tree_growth_button.pressed.connect(_on_passive_income_pressed)
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
    # Darker background for disabled buttons makes icons pop more
    style_disabled.modulate_color = Color(0.3, 0.3, 0.3, 1)
    
    btn.add_theme_stylebox_override("normal", style_normal)
    btn.add_theme_stylebox_override("hover", style_hover)
    btn.add_theme_stylebox_override("pressed", style_pressed)
    btn.add_theme_stylebox_override("disabled", style_disabled)
    btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    
    # Set the icon if Icon exists
    var icon_rect = btn.find_child("Icon", true, false)
    if icon_rect and icon_rect is TextureRect:
        icon_rect.texture = load(info.icon)
    
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
    _update_passive_income_button()

func _update_unit_button(btn: Button, type: String) -> void:
    var info = UPGRADES[type]
    var cost_hbox = btn.find_child("CostHBox", true, false)
    var cost_label = btn.find_child("CostLabel", true, false)
    var name_label = btn.find_child("NameLabel", true, false)
    
    if not name_label: return
    
    if GameState.is_unit_unlocked(type):
        name_label.text = "%s\n(Unlocked)" % info.name
        btn.disabled = true
        if cost_hbox: cost_hbox.visible = false
    else:
        name_label.text = info.name
        if cost_label: cost_label.text = str(info.cost)
        btn.disabled = GameState.trees < info.cost
        if cost_hbox: cost_hbox.visible = true

func _update_passive_income_button() -> void:
    var is_lvl4_beaten = GameState.is_level_beaten("level_4")
    var cost = GameState.get_passive_income_upgrade_cost()
    var cost_hbox = tree_growth_button.find_child("CostHBox", true, false)
    var cost_label = tree_growth_button.find_child("CostLabel", true, false)
    var name_label = tree_growth_button.find_child("NameLabel", true, false)
    var status_label = tree_growth_button.find_child("StatusLabel", true, false)
    
    if not name_label: return
    
    var income_interval = GameState.get_current_passive_income_interval(2.0)
    
    if not is_lvl4_beaten:
        name_label.text = "Passive Income\n(Beat level 4 to unlock)"
        if status_label:
            status_label.text = "Income: %0.1fs" % income_interval
            status_label.visible = true
        if cost_hbox: cost_hbox.visible = false
        tree_growth_button.disabled = true
    else:
        name_label.text = "Passive Income"
        if status_label:
            status_label.text = "Income: %0.1fs" % income_interval
            status_label.visible = true
        if cost_label: cost_label.text = str(cost)
        if cost_hbox: cost_hbox.visible = true
        tree_growth_button.disabled = GameState.trees < cost

func _buy_upgrade(type: String) -> void:
    var info = UPGRADES[type]
    if GameState.unlock_unit(type, info.cost):
        update_ui()

func _on_passive_income_pressed() -> void:
    if GameState.purchase_passive_income_upgrade():
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
