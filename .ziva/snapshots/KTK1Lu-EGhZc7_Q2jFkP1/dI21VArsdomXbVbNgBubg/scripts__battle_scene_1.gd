class_name BattleScene1
extends Node2D

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44

@export var show_attack_range_debug: bool = true

@onready var player_castle: Castle = $PlayerCastle as Castle
@onready var enemy_castle: Castle = $EnemyCastle as Castle
@onready var summon_button: Button = $UI/SummonSwordsmanButton
@onready var battle_lane_path: Path2D = $BattleLanePath
@onready var player_castle_hp_bar: ProgressBar = $UI/PlayerCastleHPBar
@onready var enemy_castle_hp_bar: ProgressBar = $UI/EnemyCastleHPBar
@onready var debug_attack_range_toggle: CheckButton = _find_debug_toggle()
@onready var debug_spawn_enemy_swordsman_button: Button = get_node_or_null("UI/DebugSpawnEnemySwordsmanButton") as Button


func _ready() -> void:
    summon_button.pressed.connect(_on_summon_swordsman_pressed)

    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.pressed.connect(_on_debug_spawn_enemy_swordsman_pressed)

    _setup_castles()

    if debug_attack_range_toggle != null:
        debug_attack_range_toggle.toggled.connect(_on_debug_attack_range_toggled)
        debug_attack_range_toggle.button_pressed = show_attack_range_debug

    _apply_debug_attack_range_to_all_soldiers()
    _apply_debug_hurtbox_to_castles()
    _apply_debug_toggle_dependent_ui()

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


func _apply_debug_attack_range_to_all_soldiers() -> void:
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var soldier: Swordsman = node as Swordsman
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


func _spawn_swordsman_for_team(team: int) -> void:
    if battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        push_warning("Cannot summon: BattleLanePath curve is not configured.")
        return

    var swordsman: Swordsman = SWORDSMAN_SCENE.instantiate() as Swordsman
    if swordsman == null:
        return

    add_child(swordsman)
    swordsman.team_id = team
    swordsman.set_debug_attack_range_visible(show_attack_range_debug)

    var starts_from_player_side: bool = team == GameConstants.TEAM_PLAYER
    swordsman.setup_lane_travel(
        battle_lane_path,
        _get_lane_offset_near_castle(starts_from_player_side),
        _get_lane_offset_near_castle(not starts_from_player_side)
    )


func _apply_debug_toggle_dependent_ui() -> void:
    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.visible = show_attack_range_debug


func _find_debug_toggle() -> CheckButton:
    var toggle: CheckButton = get_node_or_null("UI/Debug") as CheckButton
    if toggle != null:
        return toggle

    return get_node_or_null("UI/DebugRangeToggle") as CheckButton


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
