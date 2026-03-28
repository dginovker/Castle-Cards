class_name LegacySwordsman
extends AnimatedSprite2D

# Thin wrapper over CombatUnit.
# Legacy implementation text kept below as inert string.
signal health_changed(current_health: float, max_health: float)
signal died(swordsman: Node)

enum CombatState {
    IDLE,
    MOVING,
    ATTACKING,
}

@export var team_id: int = GameConstants.TEAM_PLAYER
@export var move_speed: float = 70.0
@export var target_render_height: float = 48.0

@export_range(0.0, 100.0, 0.1) var attack_range: float = GameConstants.SOLDIER_ATTACK_RANGE
@export_range(0.0, 1000.0, 1.0) var attack_damage: float = GameConstants.SOLDIER_ATTACK_DAMAGE
@export_range(1.0, 1000.0, 1.0) var max_health: float = GameConstants.SOLDIER_MAX_HEALTH
@export_range(0.1, 10.0, 0.05) var attack_interval_seconds: float = 0.55
@export_enum("Attack", "Defend") var active_mode: int = GameConstants.UNIT_MODE_ATTACK
@export_range(0.0, 1000.0, 1.0) var defend_protection_radius_pixels: float = GameConstants.SOLDIER_DEFEND_PROTECTION_RADIUS_PIXELS

@export var debug_range_fill_color: Color = Color(1.0, 0.2, 0.2, 0.14)
@export var debug_range_outline_color: Color = Color(1.0, 0.2, 0.2, 0.9)
@export_range(1.0, 8.0, 0.1) var debug_range_outline_width: float = 2.0

var lane_path: Path2D
var lane_curve: Curve2D
var current_offset: float = 0.0
var target_offset: float = 0.0
var has_target: bool = false
var debug_attack_range_visible: bool = false

var combat_state: CombatState = CombatState.IDLE
var current_health: float = 0.0
var current_target_soldier: Node
var current_target_castle: Castle
var own_castle: Castle
var enemy_castle: Castle
var lane_player_side_offset: float = 0.0
var lane_enemy_side_offset: float = 0.0
var _attack_cooldown_remaining: float = 0.0

var _attack_area: Area2D
var _attack_area_shape_node: CollisionShape2D
var _hurtbox_area: Area2D
var _hurtbox_shape_node: CollisionShape2D


func _ready() -> void:
    add_to_group(&"soldiers")
    current_health = max_health
    _apply_visual_scale()
    _ensure_attack_area()
    _ensure_hurtbox()
    refresh_attack_range_shape()
    health_changed.emit(current_health, max_health)
    stop()
    set_process(false)
    queue_redraw()


func setup_lane_travel(path: Path2D, start_offset: float, end_offset: float) -> void:
    lane_path = path
    lane_curve = path.curve if path != null else null

    if lane_curve == null:
        push_warning("Swordsman.setup_lane_travel: Missing lane curve.")
        return

    current_offset = start_offset
    target_offset = end_offset
    has_target = not is_equal_approx(current_offset, target_offset)
    combat_state = CombatState.MOVING if has_target else CombatState.IDLE

    _update_world_position_from_offset()

    flip_h = target_offset < current_offset
    if has_target and sprite_frames != null and sprite_frames.has_animation(&"walk"):
        play(&"walk")
    else:
        stop()
    set_process(true)


func set_castle_references(own: Castle, enemy: Castle) -> void:
    own_castle = own
    enemy_castle = enemy


func set_lane_side_offsets(player_side: float, enemy_side: float) -> void:
    lane_player_side_offset = player_side
    lane_enemy_side_offset = enemy_side
    _refresh_movement_target_for_mode()


func set_mode(mode: int) -> void:
    var normalized_mode: int = (
        GameConstants.UNIT_MODE_DEFEND
        if mode == GameConstants.UNIT_MODE_DEFEND
        else GameConstants.UNIT_MODE_ATTACK
    )

    active_mode = normalized_mode
    _refresh_movement_target_for_mode()


func set_debug_attack_range_visible(visible_state: bool) -> void:
    if debug_attack_range_visible == visible_state:
        return

    debug_attack_range_visible = visible_state
    queue_redraw()


func is_dead() -> bool:
    return current_health <= 0.0


func _refresh_movement_target_for_mode() -> void:
    if lane_curve == null:
        return

    target_offset = _get_mode_destination_offset()
    has_target = not is_equal_approx(current_offset, target_offset)

    if combat_state == CombatState.ATTACKING:
        return

    if has_target:
        combat_state = CombatState.MOVING
        flip_h = target_offset < current_offset
        if sprite_frames != null and sprite_frames.has_animation(&"walk"):
            play(&"walk")
        else:
            stop()
    else:
        combat_state = CombatState.IDLE
        stop()


func _get_mode_destination_offset() -> float:
    if active_mode == GameConstants.UNIT_MODE_DEFEND:
        return _get_own_side_offset()

    return _get_enemy_side_offset()


func _get_own_side_offset() -> float:
    return lane_player_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_enemy_side_offset


func _get_enemy_side_offset() -> float:
    return lane_enemy_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_player_side_offset


func take_damage(amount: float) -> void:
    if amount <= 0.0 or is_dead():
        return

    current_health = clampf(current_health - amount, 0.0, max_health)
    health_changed.emit(current_health, max_health)

    if is_zero_approx(current_health):
        died.emit(self)
        queue_free()


func get_hurtbox() -> Area2D:
    return _hurtbox_area


func get_attack_range_radius_pixels() -> float:
    return maxf(0.0, attack_range * GameConstants.ATTACK_RANGE_UNIT_PIXELS)


func refresh_attack_range_shape() -> void:
    if _attack_area_shape_node == null:
        return

    var circle_shape: CircleShape2D = _attack_area_shape_node.shape as CircleShape2D
    if circle_shape == null:
        circle_shape = CircleShape2D.new()
        _attack_area_shape_node.shape = circle_shape

    circle_shape.radius = get_attack_range_radius_pixels()


func _process(delta: float) -> void:
    _update_targets_from_attack_overlap()

    match combat_state:
        CombatState.ATTACKING:
            _process_attacking(delta)
        CombatState.MOVING:
            _process_moving(delta)
        CombatState.IDLE:
            if _has_attack_target():
                _enter_attacking_state()


func _process_moving(delta: float) -> void:
    if _has_attack_target():
        _enter_attacking_state()
        return

    if not has_target or lane_curve == null:
        combat_state = CombatState.IDLE
        stop()
        return

    current_offset = move_toward(current_offset, target_offset, move_speed * delta)
    _update_world_position_from_offset()

    if is_equal_approx(current_offset, target_offset) or absf(current_offset - target_offset) <= 0.5:
        current_offset = target_offset
        _update_world_position_from_offset()
        has_target = false
        combat_state = CombatState.IDLE
        stop()


func _process_attacking(delta: float) -> void:
    if not _has_attack_target():
        _resume_after_attack_lost_target()
        return

    if sprite_frames != null and sprite_frames.has_animation(&"fight") and animation != &"fight":
        play(&"fight")

    _attack_cooldown_remaining -= delta
    if _attack_cooldown_remaining > 0.0:
        return

    _attack_cooldown_remaining = attack_interval_seconds

    if _is_current_soldier_target_attackable():
        current_target_soldier.take_damage(attack_damage)
        return

    if _is_current_castle_target_attackable():
        current_target_castle.take_damage(attack_damage)


func _enter_attacking_state() -> void:
    if not _has_attack_target():
        return

    combat_state = CombatState.ATTACKING
    _attack_cooldown_remaining = 0.0

    if sprite_frames != null and sprite_frames.has_animation(&"fight"):
        play(&"fight")
    else:
        stop()


func _resume_after_attack_lost_target() -> void:
    if has_target and lane_curve != null and not is_equal_approx(current_offset, target_offset):
        combat_state = CombatState.MOVING
        if sprite_frames != null and sprite_frames.has_animation(&"walk"):
            play(&"walk")
        else:
            stop()
        return

    combat_state = CombatState.IDLE
    stop()


func _has_attack_target() -> bool:
    if _is_current_soldier_target_attackable():
        return true

    current_target_soldier = null

    if _is_current_castle_target_attackable():
        return true

    current_target_castle = null
    return false


func _update_targets_from_attack_overlap() -> void:
    if _attack_area == null:
        return

    current_target_soldier = null
    current_target_castle = null

    for overlap_area: Area2D in _attack_area.get_overlapping_areas():
        if overlap_area == null:
            continue

        var overlap_parent: Node = overlap_area.get_parent()

        var soldier: Node = overlap_parent
        if soldier != null:
            if soldier == self or soldier.team_id == team_id or soldier.is_dead():
                continue
            if not _is_target_allowed_for_current_mode(soldier.global_position, false):
                continue
            current_target_soldier = soldier
            current_target_castle = null
            return

        var castle: Castle = overlap_parent as Castle
        if castle != null:
            if castle.team_id == team_id or castle.is_destroyed():
                continue
            if not _is_target_allowed_for_current_mode(castle.global_position, true):
                continue
            if current_target_castle == null:
                current_target_castle = castle


func _is_current_soldier_target_attackable() -> bool:
    if current_target_soldier == null or not is_instance_valid(current_target_soldier):
        return false

    if current_target_soldier == self or current_target_soldier.team_id == team_id or current_target_soldier.is_dead():
        return false

    if not _is_target_allowed_for_current_mode(current_target_soldier.global_position, false):
        return false

    var hurtbox: Area2D = current_target_soldier.get_hurtbox()
    if hurtbox == null:
        return false

    return _attack_area != null and _attack_area.overlaps_area(hurtbox)


func _is_current_castle_target_attackable() -> bool:
    if current_target_castle == null or not is_instance_valid(current_target_castle):
        return false

    if current_target_castle.team_id == team_id or current_target_castle.is_destroyed():
        return false

    if not _is_target_allowed_for_current_mode(current_target_castle.global_position, true):
        return false

    var hurtbox: Area2D = current_target_castle.get_hurtbox()
    if hurtbox == null:
        return false

    return _attack_area != null and _attack_area.overlaps_area(hurtbox)


func _is_target_allowed_for_current_mode(target_global_position: Vector2, is_castle_target: bool) -> bool:
    if active_mode != GameConstants.UNIT_MODE_DEFEND:
        return true

    if is_castle_target:
        return false

    if own_castle == null or not is_instance_valid(own_castle):
        return true

    return own_castle.global_position.distance_to(target_global_position) <= defend_protection_radius_pixels


func _draw() -> void:
    if not debug_attack_range_visible:
        return

    var radius: float = get_attack_range_radius_pixels()
    if radius <= 0.0:
        return

    draw_circle(Vector2.ZERO, radius, debug_range_fill_color)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, debug_range_outline_color, debug_range_outline_width, true)


func _update_world_position_from_offset() -> void:
    if lane_path == null or lane_curve == null:
        return

    var lane_local_position: Vector2 = lane_curve.sample_baked(current_offset, true)
    global_position = lane_path.to_global(lane_local_position)


func _apply_visual_scale() -> void:
    if sprite_frames == null or not sprite_frames.has_animation(&"walk"):
        return

    var texture: Texture2D = sprite_frames.get_frame_texture(&"walk", 0)
    if texture == null:
        return

    var texture_height: float = texture.get_size().y
    if texture_height <= 0.0:
        return

    var scale_factor: float = target_render_height / texture_height
    scale = Vector2.ONE * scale_factor


func _ensure_attack_area() -> void:
    _attack_area = get_node_or_null("AttackArea") as Area2D
    if _attack_area == null:
        _attack_area = Area2D.new()
        _attack_area.name = "AttackArea"
        add_child(_attack_area)

    _attack_area.monitoring = true
    _attack_area.monitorable = true
    _attack_area.collision_layer = 0
    _attack_area.collision_mask = GameConstants.COMBAT_HURTBOX_LAYER

    _attack_area_shape_node = _attack_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if _attack_area_shape_node == null:
        _attack_area_shape_node = CollisionShape2D.new()
        _attack_area_shape_node.name = "CollisionShape2D"
        _attack_area.add_child(_attack_area_shape_node)

    if not (_attack_area_shape_node.shape is CircleShape2D):
        _attack_area_shape_node.shape = CircleShape2D.new()


func _ensure_hurtbox() -> void:
    _hurtbox_area = get_node_or_null("Hurtbox") as Area2D
    if _hurtbox_area == null:
        _hurtbox_area = Area2D.new()
        _hurtbox_area.name = "Hurtbox"
        add_child(_hurtbox_area)

    _hurtbox_area.monitoring = false
    _hurtbox_area.monitorable = true
    _hurtbox_area.collision_layer = GameConstants.COMBAT_HURTBOX_LAYER
    _hurtbox_area.collision_mask = 0

    _hurtbox_shape_node = _hurtbox_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if _hurtbox_shape_node == null:
        _hurtbox_shape_node = CollisionShape2D.new()
        _hurtbox_shape_node.name = "CollisionShape2D"
        _hurtbox_area.add_child(_hurtbox_shape_node)

    var circle_shape: CircleShape2D = _hurtbox_shape_node.shape as CircleShape2D
    if circle_shape == null:
        circle_shape = CircleShape2D.new()
        _hurtbox_shape_node.shape = circle_shape

    circle_shape.radius = maxf(8.0, get_attack_range_radius_pixels() * 0.25)
