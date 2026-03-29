class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/archer.tscn")
const DRUMMER_SCENE: PackedScene = preload("res://scenes/drummer.tscn")
const CANNON_SCENE: PackedScene = preload("res://scenes/cannon.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44

enum UnitMode {
    ATTACK,
    DEFEND,
}

@export var show_attack_range_debug: bool = true
@export var player_active_mode: UnitMode = UnitMode.ATTACK
@export var enemy_active_mode: UnitMode = UnitMode.ATTACK

@onready var player_castle: Castle = $PlayerCastle as Castle
@onready var enemy_castle: Castle = $EnemyCastle as Castle
@onready var summon_button: Button = $UI/SummonSwordsmanButton
@onready var summon_archer_button: Button = get_node_or_null("UI/SummonArcherButton") as Button
@onready var summon_drummer_button: Button = get_node_or_null("UI/SummonDrummerButton") as Button
@onready var summon_cannon_button: Button = get_node_or_null("UI/SummonCannonButton") as Button
@onready var battle_lane_path: Path2D = $BattleLanePath
@onready var player_cannon_mount: Node2D = get_node_or_null("PlayerCannonMount") as Node2D
@onready var enemy_cannon_mount: Node2D = get_node_or_null("EnemyCannonMount") as Node2D
@onready var player_castle_hp_bar: ProgressBar = $UI/PlayerCastleHPBar
@onready var enemy_castle_hp_bar: ProgressBar = $UI/EnemyCastleHPBar
@onready var debug_attack_range_toggle: CheckButton = _find_debug_toggle()
@onready var debug_spawn_enemy_swordsman_button: Button = get_node_or_null("UI/DebugSpawnEnemySwordsmanButton") as Button
@onready var debug_spawn_enemy_archer_button: Button = get_node_or_null("UI/DebugSpawnEnemyArcherButton") as Button
@onready var debug_spawn_enemy_drummer_button: Button = get_node_or_null("UI/DebugSpawnEnemyDrummerButton") as Button
@onready var debug_spawn_enemy_cannon_button: Button = get_node_or_null("UI/DebugSpawnEnemyCannonButton") as Button

@onready var player_mode_attack_button: Button = get_node_or_null("UI/PlayerModeAttackButton") as Button
@onready var player_mode_defend_button: Button = get_node_or_null("UI/PlayerModeDefendButton") as Button
@onready var enemy_mode_attack_button: Button = get_node_or_null("UI/EnemyModeAttackButton") as Button
@onready var enemy_mode_defend_button: Button = get_node_or_null("UI/EnemyModeDefendButton") as Button

var _player_has_purchased_cannon: bool = false
var _enemy_has_purchased_cannon: bool = false


func _ready() -> void:
    summon_button.pressed.connect(_on_summon_swordsman_pressed)

    if summon_archer_button != null:
        summon_archer_button.pressed.connect(_on_summon_archer_pressed)

    if summon_drummer_button != null:
        summon_drummer_button.pressed.connect(_on_summon_drummer_pressed)

    if summon_cannon_button != null:
        summon_cannon_button.pressed.connect(_on_summon_cannon_pressed)

    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.pressed.connect(_on_debug_spawn_enemy_swordsman_pressed)

    if debug_spawn_enemy_archer_button != null:
        debug_spawn_enemy_archer_button.pressed.connect(_on_debug_spawn_enemy_archer_pressed)

    if debug_spawn_enemy_drummer_button != null:
        debug_spawn_enemy_drummer_button.pressed.connect(_on_debug_spawn_enemy_drummer_pressed)

    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.pressed.connect(_on_debug_spawn_enemy_cannon_pressed)

    if player_mode_attack_button != null:
        player_mode_attack_button.pressed.connect(_on_player_mode_attack_pressed)
    if player_mode_defend_button != null:
        player_mode_defend_button.pressed.connect(_on_player_mode_defend_pressed)
    if enemy_mode_attack_button != null:
        enemy_mode_attack_button.pressed.connect(_on_enemy_mode_attack_pressed)
    if enemy_mode_defend_button != null:
        enemy_mode_defend_button.pressed.connect(_on_enemy_mode_defend_pressed)

    _setup_castles()

    if debug_attack_range_toggle != null:
        debug_attack_range_toggle.toggled.connect(_on_debug_attack_range_toggled)
        debug_attack_range_toggle.button_pressed = show_attack_range_debug

    _sync_mode_buttons_visuals()
    _apply_debug_attack_range_to_all_soldiers()
    _apply_debug_hurtbox_to_castles()
    _apply_debug_toggle_dependent_ui()
    if summon_cannon_button != null:
        summon_cannon_button.disabled = _player_has_purchased_cannon
        summon_cannon_button.modulate = Color(1.0, 1.0, 1.0, 0.45) if _player_has_purchased_cannon else Color(1.0, 1.0, 1.0, 1.0)
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.disabled = _enemy_has_purchased_cannon
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon

    if battle_lane_path.curve == null or battle_lane_path.curve.point_count < 2:
        push_warning("BattleLanePath.curve is missing or has fewer than 2 points. Edit BattleLanePath in the inspector to define the lane curve.")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        _set_attack_range_debug_visible(not show_attack_range_debug)


func _on_debug_attack_range_toggled(is_pressed: bool) -> void:
    _set_attack_range_debug_visible(is_pressed)


func _set_attack_range_debug_visible(visible_state: bool) -> void:
    if show_attack_range_debug == visible_state:
        return

    show_attack_range_debug = visible_state

    if debug_attack_range_toggle != null and debug_attack_range_toggle.button_pressed != visible_state:
        debug_attack_range_toggle.button_pressed = visible_state

    _apply_debug_attack_range_to_all_soldiers()
    _apply_debug_hurtbox_to_castles()
    _apply_debug_toggle_dependent_ui()
    if summon_cannon_button != null:
        summon_cannon_button.disabled = _player_has_purchased_cannon
        summon_cannon_button.modulate = Color(1.0, 1.0, 1.0, 0.45) if _player_has_purchased_cannon else Color(1.0, 1.0, 1.0, 1.0)
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.disabled = _enemy_has_purchased_cannon
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon


func _apply_debug_attack_range_to_all_soldiers() -> void:
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var soldier = node
        if soldier != null:
            soldier.set_debug_attack_range_visible(show_attack_range_debug)


func _apply_debug_hurtbox_to_castles() -> void:
    if player_castle != null:
        player_castle.set_debug_hurtbox_visible(show_attack_range_debug)

    if enemy_castle != null:
        enemy_castle.set_debug_hurtbox_visible(show_attack_range_debug)


func _setup_castles() -> void:
    if player_castle != null:
        player_castle.team_id = GameConstants.TEAM_PLAYER
        player_castle.set_debug_hurtbox_visible(show_attack_range_debug)
        player_castle.health_changed.connect(_on_player_castle_health_changed)
        player_castle.destroyed.connect(_on_castle_destroyed)
        player_castle_hp_bar.max_value = player_castle.max_health
        player_castle_hp_bar.value = player_castle.current_health

    if enemy_castle != null:
        enemy_castle.team_id = GameConstants.TEAM_ENEMY
        enemy_castle.set_debug_hurtbox_visible(show_attack_range_debug)
        enemy_castle.health_changed.connect(_on_enemy_castle_health_changed)
        enemy_castle.destroyed.connect(_on_castle_destroyed)
        enemy_castle_hp_bar.max_value = enemy_castle.max_health
        enemy_castle_hp_bar.value = enemy_castle.current_health


func _on_player_castle_health_changed(current_health: float, max_health: float) -> void:
    player_castle_hp_bar.max_value = max_health
    player_castle_hp_bar.value = current_health


func _on_enemy_castle_health_changed(current_health: float, max_health: float) -> void:
    enemy_castle_hp_bar.max_value = max_health
    enemy_castle_hp_bar.value = current_health


func _on_castle_destroyed(castle: Castle) -> void:
    print("Castle destroyed: ", castle.name)


func _on_summon_swordsman_pressed() -> void:
    _spawn_swordsman_for_team(GameConstants.TEAM_PLAYER)


func _on_debug_spawn_enemy_swordsman_pressed() -> void:
    _spawn_swordsman_for_team(GameConstants.TEAM_ENEMY)


func _on_summon_archer_pressed() -> void:
    _spawn_archer_for_team(GameConstants.TEAM_PLAYER)


func _on_debug_spawn_enemy_archer_pressed() -> void:
    _spawn_archer_for_team(GameConstants.TEAM_ENEMY)


func _on_summon_drummer_pressed() -> void:
    _spawn_drummer_for_team(GameConstants.TEAM_PLAYER)


func _on_debug_spawn_enemy_drummer_pressed() -> void:
    _spawn_drummer_for_team(GameConstants.TEAM_ENEMY)


func _on_summon_cannon_pressed() -> void:
    _spawn_cannon_for_team(GameConstants.TEAM_PLAYER)


func _on_debug_spawn_enemy_cannon_pressed() -> void:
    _spawn_cannon_for_team(GameConstants.TEAM_ENEMY)


func _on_player_mode_attack_pressed() -> void:
    player_active_mode = UnitMode.ATTACK
    _sync_mode_buttons_visuals()
    _apply_mode_to_team_soldiers(GameConstants.TEAM_PLAYER)


func _on_player_mode_defend_pressed() -> void:
    player_active_mode = UnitMode.DEFEND
    _sync_mode_buttons_visuals()
    _apply_mode_to_team_soldiers(GameConstants.TEAM_PLAYER)


func _on_enemy_mode_attack_pressed() -> void:
    enemy_active_mode = UnitMode.ATTACK
    _sync_mode_buttons_visuals()
    _apply_mode_to_team_soldiers(GameConstants.TEAM_ENEMY)


func _on_enemy_mode_defend_pressed() -> void:
    enemy_active_mode = UnitMode.DEFEND
    _sync_mode_buttons_visuals()
    _apply_mode_to_team_soldiers(GameConstants.TEAM_ENEMY)


func _spawn_swordsman_for_team(team: int) -> void:
    _spawn_unit_for_team(SWORDSMAN_SCENE, team)


func _spawn_archer_for_team(team: int) -> void:
    _spawn_unit_for_team(ARCHER_SCENE, team)


func _spawn_drummer_for_team(team: int) -> void:
    _spawn_unit_for_team(DRUMMER_SCENE, team)


func _spawn_cannon_for_team(team: int) -> void:
    if team == GameConstants.TEAM_PLAYER and _player_has_purchased_cannon:
        return
    if team == GameConstants.TEAM_ENEMY and _enemy_has_purchased_cannon:
        return

    var cannon: Node = _spawn_unit_for_team(CANNON_SCENE, team)
    if cannon == null:
        return

    if team == GameConstants.TEAM_PLAYER:
        _player_has_purchased_cannon = true
    else:
        _enemy_has_purchased_cannon = true

    var mount_node: Node2D = player_cannon_mount if team == GameConstants.TEAM_PLAYER else enemy_cannon_mount
    if mount_node != null:
        cannon.global_position = mount_node.global_position
    else:
        var castle: Castle = player_castle if team == GameConstants.TEAM_PLAYER else enemy_castle
        if castle != null:
            cannon.global_position = castle.global_position + Vector2(0.0, -24.0)

    if summon_cannon_button != null:
        summon_cannon_button.disabled = _player_has_purchased_cannon
        summon_cannon_button.modulate = Color(1.0, 1.0, 1.0, 0.45) if _player_has_purchased_cannon else Color(1.0, 1.0, 1.0, 1.0)
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.disabled = _enemy_has_purchased_cannon
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon


func _spawn_unit_for_team(scene: PackedScene, team: int) -> Node:
    if battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        push_warning("Cannot summon: BattleLanePath curve is not configured.")
        return null

    var unit: Node = scene.instantiate()
    if unit == null:
        return null

    add_child(unit)
    unit.team_id = team
    unit.set_debug_attack_range_visible(show_attack_range_debug)

    var player_side_offset: float = _get_lane_offset_near_castle(true)
    var enemy_side_offset: float = _get_lane_offset_near_castle(false)
    var starts_from_player_side: bool = team == GameConstants.TEAM_PLAYER
    var start_offset: float = player_side_offset if starts_from_player_side else enemy_side_offset

    unit.set_castle_references(
        player_castle if team == GameConstants.TEAM_PLAYER else enemy_castle,
        enemy_castle if team == GameConstants.TEAM_PLAYER else player_castle
    )
    unit.set_lane_side_offsets(player_side_offset, enemy_side_offset)

    unit.setup_lane_travel(battle_lane_path, start_offset, start_offset)
    unit.set_mode(_to_unit_mode(_get_active_mode_for_team(team)))
    return unit


func _apply_debug_toggle_dependent_ui() -> void:
    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.visible = show_attack_range_debug

    if debug_spawn_enemy_archer_button != null:
        debug_spawn_enemy_archer_button.visible = show_attack_range_debug

    if debug_spawn_enemy_drummer_button != null:
        debug_spawn_enemy_drummer_button.visible = show_attack_range_debug

    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon

    if enemy_mode_attack_button != null:
        enemy_mode_attack_button.visible = show_attack_range_debug

    if enemy_mode_defend_button != null:
        enemy_mode_defend_button.visible = show_attack_range_debug


func _find_debug_toggle() -> CheckButton:
    var toggle: CheckButton = get_node_or_null("UI/Debug") as CheckButton
    if toggle != null:
        return toggle

    return get_node_or_null("UI/DebugRangeToggle") as CheckButton


func _sync_mode_buttons_visuals() -> void:
    if player_mode_attack_button != null:
        player_mode_attack_button.button_pressed = player_active_mode == UnitMode.ATTACK

    if player_mode_defend_button != null:
        player_mode_defend_button.button_pressed = player_active_mode == UnitMode.DEFEND

    if enemy_mode_attack_button != null:
        enemy_mode_attack_button.button_pressed = enemy_active_mode == UnitMode.ATTACK

    if enemy_mode_defend_button != null:
        enemy_mode_defend_button.button_pressed = enemy_active_mode == UnitMode.DEFEND


func _get_active_mode_for_team(team: int) -> UnitMode:
    return player_active_mode if team == GameConstants.TEAM_PLAYER else enemy_active_mode


func _to_unit_mode(mode: UnitMode) -> int:
    return GameConstants.UNIT_MODE_DEFEND if mode == UnitMode.DEFEND else GameConstants.UNIT_MODE_ATTACK


func _apply_mode_to_team_soldiers(team: int) -> void:
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var soldier = node
        if soldier == null or not soldier.is_in_group(&"soldiers") or soldier.get("team_id") != team:
            continue

        soldier.set_mode(_to_unit_mode(_get_active_mode_for_team(team)))


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
