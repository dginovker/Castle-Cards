class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44

@onready var player_castle: Sprite2D = $PlayerCastle
@onready var enemy_castle: Sprite2D = $EnemyCastle
@onready var summon_button: Button = $UI/SummonSwordsmanButton


func _ready() -> void:
    summon_button.pressed.connect(_on_summon_swordsman_pressed)


func _on_summon_swordsman_pressed() -> void:
    var swordsman: Swordsman = SWORDSMAN_SCENE.instantiate() as Swordsman
    var spawn_position: Vector2 = _get_player_castle_door_position()
    var target: Vector2 = _get_enemy_castle_door_position()

    swordsman.global_position = spawn_position
    swordsman.set_target_position(target)
    add_child(swordsman)


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
