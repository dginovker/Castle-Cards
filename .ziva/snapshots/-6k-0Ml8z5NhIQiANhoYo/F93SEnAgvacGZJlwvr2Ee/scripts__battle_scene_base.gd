extends Node2D
class_name BattleSceneBase

const SWORDSMAN_SCENE: PackedScene = preload("res://scenes/swordsman.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/archer.tscn")
const DRUMMER_SCENE: PackedScene = preload("res://scenes/drummer.tscn")
const CANNON_SCENE: PackedScene = preload("res://scenes/cannon.tscn")
const WOODCUTTER_SCENE: PackedScene = preload("res://scenes/woodcutter.tscn")
const GAME_OVER_SCREEN_SCENE: PackedScene = preload("res://scenes/game_over_screen.tscn")

const DOOR_X_FACTOR: float = 0.30
const DOOR_Y_FACTOR: float = 0.44
const TREE_TEXTURE: Texture2D = preload("res://assets/tree.png")

@export var level_id: String = "level_1"
@export var show_attack_range_debug: bool = false

@export_range(0.5, 30.0, 0.1) var tree_spawn_interval_seconds: float = 4.0
@export_range(0.0, 10.0, 0.1) var tree_spawn_interval_jitter_seconds: float = 1.0
@export_range(0.5, 20.0, 0.1) var tree_growth_duration_seconds: float = 2.5
@export_range(8.0, 256.0, 1.0) var tree_target_height_pixels: float = 108.0
@export_range(0.0, 80.0, 1.0) var tree_spawn_perpendicular_jitter_pixels: float = 12.0

@onready var player_castle: Castle = $PlayerCastle as Castle
@onready var enemy_castle: Castle = $EnemyCastle as Castle
@onready var summon_button: Button = %SummonSwordsmanButton
@onready var summon_archer_button: Button = %SummonArcherButton
@onready var summon_drummer_button: Button = %SummonDrummerButton
@onready var summon_cannon_button: Button = %SummonCannonButton
@onready var summon_woodcutter_button: Button = %SummonWoodcutterButton
@onready var battle_lane_path: Path2D = $BattleLanePath
@onready var trees_container: Node2D = get_node_or_null("Trees") as Node2D
@onready var player_cannon_mount: Node2D = get_node_or_null("PlayerCannonMount") as Node2D
@onready var enemy_cannon_mount: Node2D = get_node_or_null("EnemyCannonMount") as Node2D
@onready var player_castle_hp_bar: ProgressBar = $UI/PlayerCastleHPBar
@onready var enemy_castle_hp_bar: ProgressBar = $UI/EnemyCastleHPBar
@onready var player_wood_value_label: Label = get_node_or_null("UI/PlayerWoodDisplay/PlayerWoodValue") as Label
@onready var enemy_wood_value_label: Label = get_node_or_null("UI/EnemyWoodDisplay/EnemyWoodValue") as Label
@onready var debug_attack_range_toggle: CheckButton = _find_debug_toggle()
@onready var debug_spawn_enemy_swordsman_button: Button = %DebugSpawnEnemySwordsmanButton
@onready var debug_spawn_enemy_archer_button: Button = %DebugSpawnEnemyArcherButton
@onready var debug_spawn_enemy_drummer_button: Button = %DebugSpawnEnemyDrummerButton
@onready var debug_spawn_enemy_cannon_button: Button = %DebugSpawnEnemyCannonButton
@onready var debug_spawn_enemy_woodcutter_button: Button = %DebugSpawnEnemyWoodcutterButton

var _player_has_purchased_cannon: bool = false
var _enemy_has_purchased_cannon: bool = false
var _player_wood: int = GameConstants.STARTING_WOOD
var _enemy_wood: int = GameConstants.STARTING_WOOD
var _tree_spawn_timer: Timer
var _wood_income_timer: Timer
var _game_over_screen: GameOverScreen

func _ready() -> void:
    randomize()

    summon_button.pressed.connect(_on_summon_swordsman_pressed)
    if summon_archer_button != null:
        summon_archer_button.pressed.connect(_on_summon_archer_pressed)
    if summon_drummer_button != null:
        summon_drummer_button.pressed.connect(_on_summon_drummer_pressed)
    if summon_cannon_button != null:
        summon_cannon_button.pressed.connect(_on_summon_cannon_pressed)
    if summon_woodcutter_button != null:
        summon_woodcutter_button.pressed.connect(_on_summon_woodcutter_pressed)

    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.pressed.connect(_on_debug_spawn_enemy_swordsman_pressed)
    if debug_spawn_enemy_archer_button != null:
        debug_spawn_enemy_archer_button.pressed.connect(_on_debug_spawn_enemy_archer_pressed)
    if debug_spawn_enemy_drummer_button != null:
        debug_spawn_enemy_drummer_button.pressed.connect(_on_debug_spawn_enemy_drummer_pressed)
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.pressed.connect(_on_debug_spawn_enemy_cannon_pressed)
    if debug_spawn_enemy_woodcutter_button != null:
        debug_spawn_enemy_woodcutter_button.pressed.connect(_on_debug_spawn_enemy_woodcutter_pressed)

    _setup_castles()

    if debug_attack_range_toggle != null:
        debug_attack_range_toggle.toggled.connect(_on_debug_attack_range_toggled)
        debug_attack_range_toggle.button_pressed = show_attack_range_debug

    _apply_debug_attack_range_to_all_soldiers()
    _apply_debug_hurtbox_to_castles()
    _apply_debug_toggle_dependent_ui()
    _refresh_wood_ui()
    _refresh_spawn_buttons_affordability()

    if battle_lane_path.curve == null or battle_lane_path.curve.point_count < 2:
        push_warning("BattleLanePath.curve is missing or has fewer than 2 points.")

    _setup_tree_spawning()
    _setup_wood_income()
    _setup_game_over_screen()


func _process(_delta: float) -> void:
    _update_ai()


func _update_ai() -> void:
    # This should be overridden in level scripts
    pass


func _on_ai_woodcutter_check(_tree_offset: float = 0.0) -> void:
    # This should be overridden in level scripts
    pass

func _on_tree_growing(offset: float) -> void:
    # This should be overridden in level scripts to handle AI timing
    pass

func _get_enemy_woodcutter_count() -> int:
    return _get_unit_count(Woodcutter, GameConstants.TEAM_ENEMY)

func _get_unit_count(unit_class: GDScript, team: int) -> int:
    var count: int = 0
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        if is_instance_of(node, unit_class) and node.team_id == team:
            count += 1
    return count

func _get_soldier_count_excluding_woodcutters(team: int) -> int:
    var count: int = 0
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        if node.team_id == team and not (node is Woodcutter):
            count += 1
    return count


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
        if node != null and node.has_method("set_debug_attack_range_visible"):
            node.call("set_debug_attack_range_visible", show_attack_range_debug)


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
    if _game_over_screen == null:
        return
    
    get_tree().paused = true
    if castle.team_id == GameConstants.TEAM_PLAYER:
        _game_over_screen.show_lose()
    else:
        var reward: int = 2
        if GameState.is_level_beaten(level_id):
            reward = 1
        elif player_castle.current_health >= player_castle.max_health:
            reward = 3
        
        GameState.complete_level(level_id, reward)
        _game_over_screen.show_win(reward)


func _setup_game_over_screen() -> void:
    _game_over_screen = GAME_OVER_SCREEN_SCENE.instantiate() as GameOverScreen
    add_child(_game_over_screen)
    _game_over_screen.retry_pressed.connect(_on_retry_pressed)
    _game_over_screen.main_menu_pressed.connect(_on_main_menu_pressed)


func _on_retry_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_summon_swordsman_pressed() -> void:
    _spawn_unit_for_team_with_cost(SWORDSMAN_SCENE, GameConstants.TEAM_PLAYER, GameConstants.SWORDSMAN_COST_WOOD)


func _on_debug_spawn_enemy_swordsman_pressed() -> void:
    _spawn_unit_for_team_with_cost(SWORDSMAN_SCENE, GameConstants.TEAM_ENEMY, GameConstants.SWORDSMAN_COST_WOOD)


func _on_summon_archer_pressed() -> void:
    _spawn_unit_for_team_with_cost(ARCHER_SCENE, GameConstants.TEAM_PLAYER, GameConstants.ARCHER_COST_WOOD)


func _on_debug_spawn_enemy_archer_pressed() -> void:
    _spawn_unit_for_team_with_cost(ARCHER_SCENE, GameConstants.TEAM_ENEMY, GameConstants.ARCHER_COST_WOOD)


func _on_summon_drummer_pressed() -> void:
    _spawn_unit_for_team_with_cost(DRUMMER_SCENE, GameConstants.TEAM_PLAYER, GameConstants.DRUMMER_COST_WOOD)


func _on_debug_spawn_enemy_drummer_pressed() -> void:
    _spawn_unit_for_team_with_cost(DRUMMER_SCENE, GameConstants.TEAM_ENEMY, GameConstants.DRUMMER_COST_WOOD)


func _on_summon_woodcutter_pressed() -> void:
    _spawn_unit_for_team_with_cost(WOODCUTTER_SCENE, GameConstants.TEAM_PLAYER, GameConstants.WOODCUTTER_COST_WOOD)


func _on_debug_spawn_enemy_woodcutter_pressed() -> void:
    _spawn_unit_for_team_with_cost(WOODCUTTER_SCENE, GameConstants.TEAM_ENEMY, GameConstants.WOODCUTTER_COST_WOOD)


func _on_summon_cannon_pressed() -> void:
    _spawn_cannon_for_team(GameConstants.TEAM_PLAYER)


func _on_debug_spawn_enemy_cannon_pressed() -> void:
    _spawn_cannon_for_team(GameConstants.TEAM_ENEMY)


func _spawn_unit_for_team_with_cost(scene: PackedScene, team: int, cost_wood: int) -> Node:
    if not _try_spend_wood(team, cost_wood):
        return null

    var unit: Node = _spawn_unit_for_team(scene, team)
    if unit == null:
        _add_wood(team, cost_wood)
        return null

    return unit


func _spawn_cannon_for_team(team: int) -> void:
    if team == GameConstants.TEAM_PLAYER and _player_has_purchased_cannon:
        return
    if team == GameConstants.TEAM_ENEMY and _enemy_has_purchased_cannon:
        return
    if not _try_spend_wood(team, GameConstants.CANNON_COST_WOOD):
        return

    var cannon: Node = _spawn_unit_for_team(CANNON_SCENE, team)
    if cannon == null:
        _add_wood(team, GameConstants.CANNON_COST_WOOD)
        return

    if team == GameConstants.TEAM_PLAYER:
        _player_has_purchased_cannon = true
    else:
        _enemy_has_purchased_cannon = true

    var mount_node: Node2D = player_cannon_mount if team == GameConstants.TEAM_PLAYER else enemy_cannon_mount
    if mount_node != null:
        cannon.global_position = mount_node.global_position

    var cannon_sprite: AnimatedSprite2D = cannon as AnimatedSprite2D
    if cannon_sprite != null:
        cannon_sprite.flip_h = team == GameConstants.TEAM_ENEMY

    _refresh_spawn_buttons_affordability()


func _spawn_unit_for_team(scene: PackedScene, team: int) -> Node:
    if battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        push_warning("Cannot summon: BattleLanePath curve is not configured.")
        return null

    var unit: Node = scene.instantiate()
    if unit == null:
        return null

    add_child(unit)
    unit.set("team_id", team)
    if unit.has_method("set_debug_attack_range_visible"):
        unit.call("set_debug_attack_range_visible", show_attack_range_debug)

    var player_side_offset: float = _get_lane_offset_near_castle(true)
    var enemy_side_offset: float = _get_lane_offset_near_castle(false)
    var start_offset: float = player_side_offset if team == GameConstants.TEAM_PLAYER else enemy_side_offset

    if unit.has_method("set_lane_side_offsets"):
        unit.call("set_lane_side_offsets", player_side_offset, enemy_side_offset)
    if unit.has_method("setup_lane_travel"):
        unit.call("setup_lane_travel", battle_lane_path, start_offset, start_offset)

    if unit.has_signal("wood_delivered"):
        unit.connect("wood_delivered", Callable(self, "_on_wood_delivered"))

    return unit


func _setup_wood_income() -> void:
    _wood_income_timer = Timer.new()
    _wood_income_timer.one_shot = false
    _wood_income_timer.wait_time = GameConstants.WOOD_PASSIVE_INCOME_INTERVAL_SECONDS
    _wood_income_timer.timeout.connect(_on_wood_income_timer_timeout)
    add_child(_wood_income_timer)
    _wood_income_timer.start()


func _on_wood_income_timer_timeout() -> void:
    _add_wood(GameConstants.TEAM_PLAYER, GameConstants.WOOD_PASSIVE_INCOME_AMOUNT)
    _add_wood(GameConstants.TEAM_ENEMY, GameConstants.WOOD_PASSIVE_INCOME_AMOUNT)


func _on_wood_delivered(team: int, amount: int) -> void:
    _add_wood(team, amount)


func _add_wood(team: int, amount: int) -> void:
    if amount == 0:
        return
    if team == GameConstants.TEAM_PLAYER:
        _player_wood = max(0, _player_wood + amount)
    else:
        _enemy_wood = max(0, _enemy_wood + amount)
    _refresh_wood_ui()
    _refresh_spawn_buttons_affordability()


func _try_spend_wood(team: int, amount: int) -> bool:
    var available: int = _player_wood if team == GameConstants.TEAM_PLAYER else _enemy_wood
    if available < amount:
        return false
    _add_wood(team, -amount)
    return true


func _refresh_wood_ui() -> void:
    if player_wood_value_label != null:
        player_wood_value_label.text = str(_player_wood)
    if enemy_wood_value_label != null:
        enemy_wood_value_label.text = str(_enemy_wood)


func _refresh_spawn_buttons_affordability() -> void:
    if summon_woodcutter_button != null:
        summon_woodcutter_button.get_parent().visible = GameState.is_unit_unlocked("woodcutter")
        _apply_afford_state(summon_woodcutter_button, _player_wood >= GameConstants.WOODCUTTER_COST_WOOD)
    if summon_button != null:
        summon_button.get_parent().visible = GameState.is_unit_unlocked("swordsman")
        _apply_afford_state(summon_button, _player_wood >= GameConstants.SWORDSMAN_COST_WOOD)
    if summon_archer_button != null:
        summon_archer_button.get_parent().visible = GameState.is_unit_unlocked("archer")
        _apply_afford_state(summon_archer_button, _player_wood >= GameConstants.ARCHER_COST_WOOD)
    if summon_drummer_button != null:
        summon_drummer_button.get_parent().visible = GameState.is_unit_unlocked("drummer")
        _apply_afford_state(summon_drummer_button, _player_wood >= GameConstants.DRUMMER_COST_WOOD)
    if summon_cannon_button != null:
        summon_cannon_button.get_parent().visible = GameState.is_unit_unlocked("cannon")
        _apply_afford_state(summon_cannon_button, (not _player_has_purchased_cannon) and (_player_wood >= GameConstants.CANNON_COST_WOOD))

    if debug_spawn_enemy_woodcutter_button != null:
        debug_spawn_enemy_woodcutter_button.disabled = _enemy_wood < GameConstants.WOODCUTTER_COST_WOOD
    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.disabled = _enemy_wood < GameConstants.SWORDSMAN_COST_WOOD
    if debug_spawn_enemy_archer_button != null:
        debug_spawn_enemy_archer_button.disabled = _enemy_wood < GameConstants.ARCHER_COST_WOOD
    if debug_spawn_enemy_drummer_button != null:
        debug_spawn_enemy_drummer_button.disabled = _enemy_wood < GameConstants.DRUMMER_COST_WOOD
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.disabled = _enemy_has_purchased_cannon or _enemy_wood < GameConstants.CANNON_COST_WOOD
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon


func _apply_afford_state(button: Button, can_afford: bool) -> void:
    button.disabled = not can_afford
    button.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford else Color(1.0, 1.0, 1.0, 0.45)


func _apply_debug_toggle_dependent_ui() -> void:
    if debug_spawn_enemy_swordsman_button != null:
        debug_spawn_enemy_swordsman_button.visible = show_attack_range_debug
    if debug_spawn_enemy_archer_button != null:
        debug_spawn_enemy_archer_button.visible = show_attack_range_debug
    if debug_spawn_enemy_drummer_button != null:
        debug_spawn_enemy_drummer_button.visible = show_attack_range_debug
    if debug_spawn_enemy_woodcutter_button != null:
        debug_spawn_enemy_woodcutter_button.visible = show_attack_range_debug
    if debug_spawn_enemy_cannon_button != null:
        debug_spawn_enemy_cannon_button.visible = show_attack_range_debug and not _enemy_has_purchased_cannon
    _refresh_spawn_buttons_affordability()


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

    var door_global_position: Vector2 = _get_castle_door_position(player_castle if is_player_side else enemy_castle, is_player_side)
    var door_local_position: Vector2 = battle_lane_path.to_local(door_global_position)
    return clampf(curve.get_closest_offset(door_local_position), 0.0, lane_length)


func _get_castle_door_position(castle: Sprite2D, is_player_side: bool) -> Vector2:
    if castle.texture == null:
        return castle.global_position
    var texture_size: Vector2 = castle.texture.get_size()
    var scaled_size: Vector2 = Vector2(texture_size.x * absf(castle.scale.x), texture_size.y * absf(castle.scale.y))
    var x_offset: float = scaled_size.x * DOOR_X_FACTOR
    var y_offset: float = scaled_size.y * DOOR_Y_FACTOR
    var direction: float = 1.0 if is_player_side else -1.0
    return castle.global_position + Vector2(direction * x_offset, y_offset)


func _setup_tree_spawning() -> void:
    if TREE_TEXTURE == null:
        return
    if battle_lane_path == null or battle_lane_path.curve == null or battle_lane_path.curve.get_baked_length() <= 0.0:
        return
    if trees_container == null:
        trees_container = Node2D.new()
        trees_container.name = "Trees"
        add_child(trees_container)

    _tree_spawn_timer = Timer.new()
    _tree_spawn_timer.one_shot = true
    _tree_spawn_timer.timeout.connect(_on_tree_spawn_timer_timeout)
    add_child(_tree_spawn_timer)
    _schedule_next_tree_spawn()


func _on_tree_spawn_timer_timeout() -> void:
    _spawn_growing_tree()
    _schedule_next_tree_spawn()


func _schedule_next_tree_spawn() -> void:
    if _tree_spawn_timer == null:
        return
    var wait_time: float = tree_spawn_interval_seconds
    if tree_spawn_interval_jitter_seconds > 0.0:
        wait_time += randf_range(-tree_spawn_interval_jitter_seconds, tree_spawn_interval_jitter_seconds)
    _tree_spawn_timer.wait_time = maxf(0.1, wait_time)
    _tree_spawn_timer.start()


func _spawn_growing_tree() -> void:
    if trees_container == null or battle_lane_path == null or battle_lane_path.curve == null or TREE_TEXTURE == null:
        return

    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    if lane_length <= 0.0:
        return

    var player_side_offset: float = _get_lane_offset_near_castle(true)
    var enemy_side_offset: float = _get_lane_offset_near_castle(false)
    var min_offset: float = minf(player_side_offset, enemy_side_offset)
    var max_offset: float = maxf(player_side_offset, enemy_side_offset)
    var offset: float = randf_range(min_offset, max_offset)
    
    # Trigger AI logic
    _on_tree_growing(offset)

    var lane_local_position: Vector2 = curve.sample_baked(offset, true)

    var sample_delta: float = 8.0
    var point_before: Vector2 = curve.sample_baked(maxf(0.0, offset - sample_delta), true)
    var point_after: Vector2 = curve.sample_baked(minf(lane_length, offset + sample_delta), true)
    var tangent: Vector2 = (point_after - point_before).normalized()
    var normal: Vector2 = tangent.orthogonal().normalized()
    if normal == Vector2.ZERO:
        normal = Vector2.UP

    var perpendicular_jitter: float = randf_range(-tree_spawn_perpendicular_jitter_pixels, tree_spawn_perpendicular_jitter_pixels)
    var spawn_position: Vector2 = battle_lane_path.to_global(lane_local_position) + normal * perpendicular_jitter

    var tree_sprite: Sprite2D = Sprite2D.new()
    tree_sprite.texture = TREE_TEXTURE
    tree_sprite.centered = true
    tree_sprite.global_position = spawn_position
    tree_sprite.z_index = 0
    tree_sprite.add_to_group(&"trees")
    tree_sprite.set_meta("is_fully_grown", false)
    tree_sprite.set_meta("lane_offset", offset)

    var texture_height: float = maxf(1.0, TREE_TEXTURE.get_height())
    var uniform_scale: float = tree_target_height_pixels / texture_height
    var final_scale: Vector2 = Vector2(uniform_scale, uniform_scale)

    tree_sprite.scale = Vector2.ZERO
    tree_sprite.modulate = Color(1.0, 1.0, 1.0, 0.7)
    trees_container.add_child(tree_sprite)

    var grow_tween: Tween = create_tween()
    grow_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    grow_tween.tween_property(tree_sprite, "scale", final_scale, tree_growth_duration_seconds)
    grow_tween.parallel().tween_property(tree_sprite, "modulate:a", 1.0, tree_growth_duration_seconds)
    grow_tween.finished.connect(_on_tree_growth_finished.bind(tree_sprite))


func _on_tree_growth_finished(tree_sprite: Sprite2D) -> void:
    if tree_sprite == null or not is_instance_valid(tree_sprite):
        return
    tree_sprite.set_meta("is_fully_grown", true)
