class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44
const CASTLE_MAX_HP: int = 20

const PLAYER_UNITS_GROUP: StringName = &"units_player"
const ENEMY_UNITS_GROUP: StringName = &"units_enemy"

@onready var player_castle: Sprite2D = $PlayerCastle
@onready var enemy_castle: Sprite2D = $EnemyCastle
@onready var summon_button: Button = $UI/SummonSwordsmanButton
@onready var debug_attack_range_toggle: CheckButton = get_node_or_null("UI/DebugAttackRangeToggle") as CheckButton
@onready var battle_lane_path: Path2D = $BattleLanePath
@onready var player_castle_hp_bar: ProgressBar = get_node_or_null("UI/PlayerCastleHPBar") as ProgressBar
@onready var enemy_castle_hp_bar: ProgressBar = get_node_or_null("UI/EnemyCastleHPBar") as ProgressBar

var player_castle_hp: int = CASTLE_MAX_HP
var enemy_castle_hp: int = CASTLE_MAX_HP
var debug_attack_range_enabled: bool = false
var player_swordsmen: Array[Swordsman] = []
var enemy_swordsmen: Array[Swordsman] = []

var player_castle_attack_point: Node2D
var enemy_castle_attack_point: Node2D


func _ready() -> void:
    summon_button.pressed.connect(_on_summon_swordsman_pressed)

    _create_castle_attack_points()

    if debug_attack_range_toggle != null:
        debug_attack_range_toggle.toggled.connect(_on_debug_attack_range_toggled)

    if player_castle_hp_bar != null:
        player_castle_hp_bar.max_value = CASTLE_MAX_HP
        player_castle_hp_bar.value = player_castle_hp

    if enemy_castle_hp_bar != null:
        enemy_castle_hp_bar.max_value = CASTLE_MAX_HP
        enemy_castle_hp_bar.value = enemy_castle_hp

    if battle_lane_path.curve == null or battle_lane_path.curve.point_count < 2:
        push_warning("BattleLanePath.curve is missing or has fewer than 2 points. Edit BattleLanePath in the inspector to define the lane curve.")


func _on_summon_swordsman_pressed() -> void:
    _spawn_swordsman(Swordsman.Team.PLAYER)


func _spawn_swordsman(team: Swordsman.Team) -> void:
    if battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        push_warning("Cannot summon: BattleLanePath curve is not configured.")
        return

    var swordsman: Swordsman = SWORDSMAN_SCENE.instantiate() as Swordsman
    swordsman.team = team

    add_child(swordsman)

    var from_player_side: bool = team == Swordsman.Team.PLAYER
    swordsman.setup_lane_travel(
        battle_lane_path,
        _get_lane_offset_near_castle(from_player_side),
        _get_lane_offset_near_castle(not from_player_side)
    )

    if team == Swordsman.Team.PLAYER:
        swordsman.add_to_group(PLAYER_UNITS_GROUP)
        swordsman.setup_combat(enemy_castle_attack_point, ENEMY_UNITS_GROUP)
        swordsman.attack_landed.connect(_on_player_attack_landed)
        player_swordsmen.append(swordsman)
    else:
        swordsman.add_to_group(ENEMY_UNITS_GROUP)
        swordsman.setup_combat(player_castle_attack_point, PLAYER_UNITS_GROUP)
        swordsman.attack_landed.connect(_on_enemy_attack_landed)
        enemy_swordsmen.append(swordsman)

    swordsman.set_debug_attack_range_enabled(debug_attack_range_enabled)
    swordsman.tree_exited.connect(func() -> void:
        player_swordsmen.erase(swordsman)
        enemy_swordsmen.erase(swordsman)
    )


func _on_player_attack_landed(_attacker: Swordsman, target: Node2D, damage: int) -> void:
    if target is Swordsman:
        (target as Swordsman).take_damage(damage)
        return

    if (target == enemy_castle_attack_point or target == enemy_castle) and enemy_castle_hp > 0:
        enemy_castle_hp = maxi(0, enemy_castle_hp - damage)
        if enemy_castle_hp_bar != null:
            enemy_castle_hp_bar.value = enemy_castle_hp


func _on_enemy_attack_landed(_attacker: Swordsman, target: Node2D, damage: int) -> void:
    if target is Swordsman:
        (target as Swordsman).take_damage(damage)
        return

    if (target == player_castle_attack_point or target == player_castle) and player_castle_hp > 0:
        player_castle_hp = maxi(0, player_castle_hp - damage)
        if player_castle_hp_bar != null:
            player_castle_hp_bar.value = player_castle_hp


func _on_debug_attack_range_toggled(button_pressed: bool) -> void:
    debug_attack_range_enabled = button_pressed

    for swordsman in player_swordsmen:
        if is_instance_valid(swordsman):
            swordsman.set_debug_attack_range_enabled(button_pressed)

    for swordsman in enemy_swordsmen:
        if is_instance_valid(swordsman):
            swordsman.set_debug_attack_range_enabled(button_pressed)


func _create_castle_attack_points() -> void:
    player_castle_attack_point = Node2D.new()
    player_castle_attack_point.name = "PlayerCastleAttackPoint"
    add_child(player_castle_attack_point)
    player_castle_attack_point.global_position = _get_player_castle_door_position()

    enemy_castle_attack_point = Node2D.new()
    enemy_castle_attack_point.name = "EnemyCastleAttackPoint"
    add_child(enemy_castle_attack_point)
    enemy_castle_attack_point.global_position = _get_enemy_castle_door_position()


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
