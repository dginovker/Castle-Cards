class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44
const LANE_HANDLE_X_FACTOR: float = 0.35
const LANE_HANDLE_Y: float = 56.0

@onready var player_castle: Sprite2D = $PlayerCastle
@onready var enemy_castle: Sprite2D = $EnemyCastle
@onready var summon_button: Button = $UI/SummonSwordsmanButton
@onready var battle_lane_path: Path2D = $BattleLanePath


func _ready() -> void:
    _rebuild_battle_lane_curve()
    summon_button.pressed.connect(_on_summon_swordsman_pressed)


func _on_summon_swordsman_pressed() -> void:
    var swordsman: Swordsman = SWORDSMAN_SCENE.instantiate() as Swordsman

    add_child(swordsman)
    swordsman.setup_lane_travel(
        battle_lane_path,
        _get_lane_offset_near_castle(true),
        _get_lane_offset_near_castle(false)
    )


func _rebuild_battle_lane_curve() -> void:
    var start_position: Vector2 = _get_player_castle_door_position()
    var end_position: Vector2 = _get_enemy_castle_door_position()

    if battle_lane_path.curve == null:
        battle_lane_path.curve = Curve2D.new()

    var curve: Curve2D = battle_lane_path.curve
    curve.clear_points()

    var x_distance: float = absf(end_position.x - start_position.x)
    var handle_x: float = maxf(64.0, x_distance * LANE_HANDLE_X_FACTOR)
    var handle_y: float = LANE_HANDLE_Y

    curve.add_point(
        battle_lane_path.to_local(start_position),
        Vector2.ZERO,
        Vector2(handle_x, handle_y)
    )
    curve.add_point(
        battle_lane_path.to_local(end_position),
        Vector2(-handle_x, handle_y),
        Vector2.ZERO
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
