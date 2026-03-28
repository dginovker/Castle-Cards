class_name Swordsman
extends AnimatedSprite2D

enum CombatState {
    IDLE,
    MOVING,
    ATTACKING,
}

@export var team_id: int = GameConstants.TEAM_PLAYER
@export var move_speed: float = 110.0
@export var target_render_height: float = 48.0

@export_range(0.0, 100.0, 0.1) var attack_range: float = 2.0
@export_range(1.0, 1000.0, 1.0) var attack_damage: float = 1.0
@export_range(0.1, 10.0, 0.05) var attack_interval_seconds: float = 0.55

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
var current_target_castle: Castle
var _attack_cooldown_remaining: float = 0.0

var _attack_area: Area2D
var _attack_area_shape_node: CollisionShape2D


func _ready() -> void:
    add_to_group(&"soldiers")
    _apply_visual_scale()
    _ensure_attack_area()
    refresh_attack_range_shape()
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
    has_target = true
    combat_state = CombatState.MOVING

    _update_world_position_from_offset()

    flip_h = target_offset < current_offset
    if sprite_frames != null and sprite_frames.has_animation(&"walk"):
        play(&"walk")
    set_process(true)


func set_debug_attack_range_visible(visible_state: bool) -> void:
    if debug_attack_range_visible == visible_state:
        return

    debug_attack_range_visible = visible_state
    queue_redraw()


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
    _update_castle_target_from_attack_overlap()

    match combat_state:
        CombatState.ATTACKING:
            _process_attacking(delta)
        CombatState.MOVING:
            _process_moving(delta)
        CombatState.IDLE:
            if current_target_castle != null:
                _enter_attacking_state()


func _process_moving(delta: float) -> void:
    if current_target_castle != null:
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
    if not _is_current_castle_target_attackable():
        current_target_castle = null
        _resume_after_attack_lost_target()
        return

    if sprite_frames != null and sprite_frames.has_animation(&"fight") and animation != &"fight":
        play(&"fight")

    _attack_cooldown_remaining -= delta
    if _attack_cooldown_remaining > 0.0:
        return

    _attack_cooldown_remaining = attack_interval_seconds
    current_target_castle.take_damage(attack_damage)


func _enter_attacking_state() -> void:
    if current_target_castle == null:
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


func _update_castle_target_from_attack_overlap() -> void:
    if _attack_area == null:
        return

    if _is_current_castle_target_attackable():
        return

    current_target_castle = null

    for overlap_area: Area2D in _attack_area.get_overlapping_areas():
        if overlap_area == null:
            continue

        var castle: Castle = overlap_area.get_parent() as Castle
        if castle == null:
            continue

        if castle.team_id == team_id or castle.is_destroyed():
            continue

        current_target_castle = castle
        return


func _is_current_castle_target_attackable() -> bool:
    if current_target_castle == null or not is_instance_valid(current_target_castle):
        return false

    if current_target_castle.team_id == team_id or current_target_castle.is_destroyed():
        return false

    var hurtbox: Area2D = current_target_castle.get_hurtbox()
    if hurtbox == null:
        return false

    return _attack_area != null and _attack_area.overlaps_area(hurtbox)


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
