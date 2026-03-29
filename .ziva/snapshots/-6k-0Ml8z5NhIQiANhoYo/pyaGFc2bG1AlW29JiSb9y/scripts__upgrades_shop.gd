extends Node2D

@onready var archer_button: Button = %ArcherButton
@onready var drummer_button: Button = %DrummerButton
@onready var cannon_button: Button = %CannonButton
@onready var back_button: Button = %BackButton

const UPGRADES = {
    "archer": {"cost": 8, "name": "Archer"},
    "drummer": {"cost": 15, "name": "Drummer"},
    "cannon": {"cost": 30, "name": "Cannon"}
}

func _ready() -> void:
    update_ui()
    GameState.trees_changed.connect(_on_trees_changed)
    
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
    _update_button(archer_button, "archer")
    _update_button(drummer_button, "drummer")
    _update_button(cannon_button, "cannon")

func _update_button(btn: Button, type: String) -> void:
    var info = UPGRADES[type]
    var action_label: Label = btn.get_node("Content/ActionLabel")
    var cost_container: Control = btn.get_node("Content/CostContainer")
    var cost_label: Label = cost_container.get_node("CostLabel")
    
    if GameState.is_unit_unlocked(type):
        action_label.text = "%s: Unlocked" % info.name
        btn.disabled = true
        cost_container.visible = false
    else:
        action_label.text = "Unlock %s " % info.name
        cost_label.text = str(info.cost)
        btn.disabled = GameState.trees < info.cost
        cost_container.visible = true

func _buy_upgrade(type: String) -> void:
    var info = UPGRADES[type]
    if GameState.unlock_unit(type, info.cost):
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
