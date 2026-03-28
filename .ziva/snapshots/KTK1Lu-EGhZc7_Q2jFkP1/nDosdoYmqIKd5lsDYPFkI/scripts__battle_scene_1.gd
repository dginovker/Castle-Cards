class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44

@export var show_attack_range_debug: bool = false

@onready var player_castle: Sprite2D = $PlayerCastle
@onready var enemy_castle: Sprite2D = $EnemyCastle
@onready var summon_button: Button = $UI/SummonSwordsmanButton
@onready var battle_lane_path: Path2D = $BattleLanePath
@onready var debug_attack_range_toggle: CheckButton = get_node_or_null("UI/DebugAttackRangeToggle") as CheckButton


func _ready() -> void:
    summon_button.pressed.connect(_on_summon_swordsman_pressed)

    if debug_attack_range_toggle != null:
        debug_attack_range_toggle.toggled.connect(_on_debug_attack_range_toggled)
        debug_attack_range_toggle.button_pressed = show_attack_range_debug

    _apply_debug_attack_range_to_all_soldiers()

    if battle_lane_path.curve == null or battle_lane_path.curve.point_count < 2:
        push_warning("BattleLanePath.curve is missing or has fewer than 2 points. Edit BattleLanePath in the inspector to define the lane curve.")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        _set_attack_range_debug_visible(not show_attack_range_debug)


func _on_debug_attack_range_toggled(is_pressed: bool) -> void:
    _set_attack_range_debug_visible(is_pressed)


func _set_attack_range_debug_visible(is_visible: bool) -> void:
    if show_attack_range_debug == is_visible:
        return

    show_attack_range_debug = is_visible

    if debug_attack_range_toggle != null and debug_attack_range_toggle.button_pressed != is_visible:
        debug_attack_range_toggle.button_pressed = is_visible

    _apply_debug_attack_range_to_all_soldiers()


func _apply_debug_attack_range_to_all_soldiers() -> void:
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var soldier: Swordsman = node as Swordsman
        if soldier != null:
            soldier.set_debug_attack_range_visible(show_attack_range_debug)


func _on_summon_swordsman_pressed() -> void:
    if battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        push_warning("Cannot summon: BattleLanePath curve is not configured.")
        return

    var swordsman: Swordsman = SWORDSMAN_SCENE.instantiate() as Swordsman

    add_child(swordsman)
    swordsman.set_debug_attack_range_visible(show_attack_range_debug)
    swordsman.setup_lane_travel(
        battle_lane_path,
        _get_lane_offset_near_castle(true),
        _get_lane_offset_near_castle(false)
    )


func _get_lane_offset_near_castle(is_player_side: bool) -> float:
    var curve: Curve2D = battle_lane_path.curve
    if curve == null:
        return 0.0

    var lane_length: float = curve.get_baked_length()
    if lane_length <= 0.0:
        return 0.0

    var door_global_position: Vector2 = (
        _get_player_castle_door_position()
        if is_player_side
        else _get_enemy_castle_door_position()
    )

    var door_local_position: Vector2 = battle_lane_path.to_local(door_global_position)
    return clampf(curve.get_closest_offset(door_local_position), 0.0, lane_length)


func _get_player_castle_door_position() -> Vector2:
    return _get_castle_door_position(player_castle, true)


func _get_enemy_castle_door_position() -> Vector2:
    return _get_castle_door_position(enemy_castle, false)


func _get_castle_door_position(castle: Sprite2D, is_player_side: bool) -> Vector2:
    if castle.texture == null:
        return castle.global_position

    var texture_size: Vector2 = castle.texture.get_size()
    var scaled_size: Vector2 = Vector2(
        texture_size.x * absf(castle.scale.x),
        texture_size.y * absf(castle.scale.y)
    )

    var x_offset: float = scaled_size.x * DOOR_X_FACTOR
    var y_offset: float = scaled_size.y * DOOR_Y_FACTOR
    var direction: float = 1.0 if is_player_side else -1.0

    return castle.global_position + Vector2(direction * x_offset, y_offset)
