extends Node2D

@onready var archer_button: Button = %ArcherButton
@onready var drummer_button: Button = %DrummerButton
@onready var cannon_button: Button = %CannonButton
@onready var back_button: Button = %BackButton

@onready var archer_cost_display: Control = %ArcherCost
@onready var drummer_cost_display: Control = %DrummerCost
@onready var cannon_cost_display: Control = %CannonCost

const UPGRADES = {
    "archer": {"cost": 8, "name": "Archer"},
    "drummer": {"cost": 15, "name": "Drummer"},
    "cannon": {"cost": 30, "name": "Cannon"}
}

func _ready() -> void:
    update_ui()
    get_node("/root/GameState").trees_changed.connect(_on_trees_changed)
    
    archer_button.pressed.connect(func(): _buy_upgrade("archer"))
    drummer_button.pressed.connect(func(): _buy_upgrade("drummer"))
    cannon_button.pressed.connect(func(): _buy_upgrade("cannon"))
    back_button.pressed.connect(_on_back_pressed)
    
    for btn in [archer_button, drummer_button, cannon_button, back_button]:
        btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
        btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))

func _on_trees_changed(_new_count: int) -> void:
    update_ui()

func update_ui() -> void:
    _update_button(archer_button, archer_cost_display, "archer")
    _update_button(drummer_button, drummer_cost_display, "drummer")
    _update_button(cannon_button, cannon_cost_display, "cannon")

func _update_button(btn: Button, cost_display: Control, type: String) -> void:
    var info = UPGRADES[type]
    var gs = get_node("/root/GameState")
    if gs.is_unit_unlocked(type):
        btn.text = "%s: Unlocked" % info.name
        btn.disabled = true
        cost_display.visible = false
    else:
        btn.text = "Unlock %s" % info.name
        btn.disabled = gs.trees < info.cost
        cost_display.visible = true

func _buy_upgrade(type: String) -> void:
    var info = UPGRADES[type]
    if get_node("/root/GameState").unlock_unit(type, info.cost):
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
