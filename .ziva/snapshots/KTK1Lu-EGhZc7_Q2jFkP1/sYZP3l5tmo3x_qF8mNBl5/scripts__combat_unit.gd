class_name CombatUnit
extends AnimatedSprite2D

signal health_changed(current_health: float, max_health: float)
signal died(unit: Node)

enum CombatState {
    IDLE,
    MOVING,
    ATTACKING,
}

@export var unit_archetype_name: String = "soldier"
@export var team_id: int = GameConstants.TEAM_PLAYER
@export var move_speed: float = 70.0
@export var target_render_height: float = 48.0

@export_range(0.0, 30.0, 1) var attack_range: float = GameConstants.SOLDIER_ATTACK_RANGE
@export_range(0.0, 10.0, 0.1) var attack_damage: float = GameConstants.SOLDIER_ATTACK_DAMAGE
@export_range(0.0, 30.0, 0.1) var max_health: float = GameConstants.SOLDIER_MAX_HEALTH
@export_range(0.1, 10.0, 0.05) var attack_interval_seconds: float = 0.55
@export_enum("Attack", "Defend") var active_mode: int = GameConstants.UNIT_MODE_ATTACK
@export_range(0.0, 1000.0, 1.0) var defend_protection_radius_pixels: float = GameConstants.SOLDIER_DEFEND_PROTECTION_RADIUS_PIXELS
@export var defend_limit_targets_near_own_castle: bool = true
@export var can_attack_castles_in_defend: bool = false

# Formation / positioning behavior (composition by data)
@export var attack_uses_frontline_anchor: bool = false
@export var frontline_anchor_excluded_archetype_name: String = ""
@export_range(0.0, 1000.0, 1.0) var frontline_follow_distance_pixels: float = 56.0
@export_range(0.0, 1000.0, 1.0) var defend_retreat_distance_pixels: float = 0.0

# Visual anti-stacking offset (units still pass through each other)
@export_range(0.0, 64.0, 1.0) var formation_y_spread_pixels: float = 12.0
@export_range(1, 15, 1) var formation_y_slots: int = 7

@export var debug_range_fill_color: Color = Color(1.0, 0.2, 0.2, 0.14)
@export var debug_range_outline_color: Color = Color(1.0, 0.2, 0.2, 0.9)
@export_range(1.0, 8.0, 0.1) var debug_range_outline_width: float = 2.0
@export var debug_leadership_range_fill_color: Color = Color(0.35, 0.8, 1.0, 0.12)
@export var debug_leadership_range_outline_color: Color = Color(0.55, 0.9, 1.0, 0.9)
@export_range(1.0, 8.0, 0.1) var debug_leadership_range_outline_width: float = 2.0

@export var show_health_bar: bool = true
@export var show_health_bar_only_when_damaged: bool = true
@export var health_bar_bg_color: Color = Color(0.08, 0.08, 0.08, 0.9)
@export var health_bar_fill_color: Color = Color(0.2, 0.95, 0.25, 1.0)
@export var health_bar_border_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export_range(8.0, 80.0, 1.0) var health_bar_width_pixels: float = 34.0
@export_range(2.0, 16.0, 1.0) var health_bar_height_pixels: float = 5.0
@export_range(0.0, 40.0, 1.0) var health_bar_vertical_offset_pixels: float = 18.0

@export var leadership_aura_color: Color = Color(0.45, 0.85, 1.0, 0.22)
@export var leadership_aura_outline_color: Color = Color(0.7, 0.95, 1.0, 0.7)
@export_range(0.0, 2.0, 0.01) var leadership_aura_full_intensity_bonus: float = 1.0
@export_range(0.0, 64.0, 1.0) var leadership_aura_radius_padding_pixels: float = 8.0
@export_range(1.0, 8.0, 0.1) var leadership_aura_outline_width: float = 1.5

@export var provides_leadership: bool = false
@export var leadership_kind: StringName = &""
@export_range(0.0, 2.0, 0.01) var leadership_bonus_amount: float = 0.0
@export_range(0.0, 30.0, 1.0) var leadership_range: float = 0.0
@export_range(0.05, 1.0, 0.01) var leadership_refresh_interval_seconds: float = 0.2

var lane_path: Path2D
var lane_curve: Curve2D
var current_offset: float = 0.0
var target_offset: float = 0.0
var has_target: bool = false
var debug_attack_range_visible: bool = false
var debug_force_show_health_bar: bool = false

var combat_state: CombatState = CombatState.IDLE
var current_health: float = 0.0
var current_target_unit: Node
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
var _formation_y_offset_pixels: float = 0.0
var _leadership_bonus_by_kind: Dictionary = {}
var _leadership_sources_by_kind: Dictionary = {}
var _leadership_refresh_remaining: float = 0.0
var _leadership_applied_targets: Dictionary = {}

static var _formation_spawn_counter: int = 0


func _ready() -> void:
    add_to_group(&"soldiers")
    current_health = max_health
    _leadership_refresh_remaining = 0.0
    _assign_formation_y_offset()
    _apply_visual_scale()
    _ensure_attack_area()
    _ensure_hurtbox()
    refresh_attack_range_shape()
    health_changed.emit(current_health, max_health)
    stop()
    set_process(false)
    queue_redraw()


func _exit_tree() -> void:
    _clear_leadership_from_previous_targets()


func setup_lane_travel(path: Path2D, start_offset: float, end_offset: float) -> void:
    lane_path = path
    lane_curve = path.curve if path != null else null

    if lane_curve == null:
        push_warning("CombatUnit.setup_lane_travel: Missing lane curve.")
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
    if debug_attack_range_visible == visible_state and debug_force_show_health_bar == visible_state:
        return

    debug_attack_range_visible = visible_state
    debug_force_show_health_bar = visible_state
    queue_redraw()


func is_dead() -> bool:
    return current_health <= 0.0


func set_leadership_bonus_from_source(kind: StringName, source: Object, bonus_amount: float) -> void:
    if kind == StringName():
        return

    if source == null:
        return

    var source_key: String = str(source.get_instance_id())
    var per_kind: Dictionary = _leadership_sources_by_kind.get(kind, {})
    var normalized_bonus: float = maxf(0.0, bonus_amount)

    if normalized_bonus <= 0.0:
        if per_kind.erase(source_key):
            if per_kind.is_empty():
                _leadership_sources_by_kind.erase(kind)
            else:
                _leadership_sources_by_kind[kind] = per_kind
            _recompute_leadership_bonus_cache()
        return

    var previous: float = float(per_kind.get(source_key, -1.0))
    if is_equal_approx(previous, normalized_bonus):
        return

    per_kind[source_key] = normalized_bonus
    _leadership_sources_by_kind[kind] = per_kind
    _recompute_leadership_bonus_cache()


func clear_leadership_bonus_from_source(kind: StringName, source: Object) -> void:
    if source == null:
        return

    var source_key: String = str(source.get_instance_id())
    var per_kind: Dictionary = _leadership_sources_by_kind.get(kind, {})
    if per_kind.erase(source_key):
        if per_kind.is_empty():
            _leadership_sources_by_kind.erase(kind)
        else:
            _leadership_sources_by_kind[kind] = per_kind
        _recompute_leadership_bonus_cache()


func set_leadership_bonus_for_kind(kind: StringName, bonus_amount: float) -> void:
    # Compatibility helper for single-source leadership setters.
    set_leadership_bonus_from_source(kind, self, bonus_amount)


func clear_leadership_bonus_for_kind(kind: StringName) -> void:
    clear_leadership_bonus_from_source(kind, self)


func clear_all_leadership_bonuses() -> void:
    if _leadership_sources_by_kind.is_empty() and _leadership_bonus_by_kind.is_empty():
        return

    _leadership_sources_by_kind.clear()
    _leadership_bonus_by_kind.clear()
    queue_redraw()


func get_total_leadership_bonus() -> float:
    var total: float = 0.0
    for value: Variant in _leadership_bonus_by_kind.values():
        total += maxf(0.0, float(value))
    return total


func has_leadership_bonus() -> bool:
    return get_total_leadership_bonus() > 0.0


func _get_effective_attack_damage() -> float:
    return attack_damage * (1.0 + get_total_leadership_bonus())


func _get_leadership_radius_pixels() -> float:
    return maxf(0.0, leadership_range * GameConstants.ATTACK_RANGE_UNIT_PIXELS)


func _recompute_leadership_bonus_cache() -> void:
    var recomputed: Dictionary = {}

    for kind_variant: Variant in _leadership_sources_by_kind.keys():
        var kind: StringName = kind_variant
        var per_kind: Dictionary = _leadership_sources_by_kind.get(kind, {})
        var strongest_for_kind: float = 0.0
        for source_bonus: Variant in per_kind.values():
            strongest_for_kind = maxf(strongest_for_kind, maxf(0.0, float(source_bonus)))

        if strongest_for_kind > 0.0:
            recomputed[kind] = strongest_for_kind

    _leadership_bonus_by_kind = recomputed
    queue_redraw()


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
        return _get_defend_destination_offset()

    return _get_attack_destination_offset()


func _get_attack_destination_offset() -> float:
    if not attack_uses_frontline_anchor:
        return _get_enemy_side_offset()

    var result: Dictionary = _find_frontline_anchor_offset()
    if not result.get("found", false):
        return _get_enemy_side_offset()

    var frontline_offset: float = result.get("offset", _get_enemy_side_offset())
    var desired_offset: float = (
        frontline_offset - frontline_follow_distance_pixels
        if team_id == GameConstants.TEAM_PLAYER
        else frontline_offset + frontline_follow_distance_pixels
    )

    return _clamp_to_lane_bounds(desired_offset)


func _get_defend_destination_offset() -> float:
    var own_side_offset: float = _get_own_side_offset()

    if defend_retreat_distance_pixels <= 0.0:
        return own_side_offset

    var desired_offset: float = (
        own_side_offset - defend_retreat_distance_pixels
        if team_id == GameConstants.TEAM_PLAYER
        else own_side_offset + defend_retreat_distance_pixels
    )

    return _clamp_to_lane_bounds(desired_offset)


func _find_frontline_anchor_offset() -> Dictionary:
    if lane_curve == null or lane_path == null:
        return {"found": false, "offset": 0.0}

    var found: bool = false
    var selected_offset: float = 0.0

    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var unit: Node = node
        if not _is_valid_frontline_anchor(unit):
            continue

        var ally_offset: float = lane_curve.get_closest_offset(lane_path.to_local(unit.global_position))

        if not found:
            selected_offset = ally_offset
            found = true
        elif team_id == GameConstants.TEAM_PLAYER and ally_offset > selected_offset:
            selected_offset = ally_offset
        elif team_id == GameConstants.TEAM_ENEMY and ally_offset < selected_offset:
            selected_offset = ally_offset

    return {
        "found": found,
        "offset": selected_offset,
    }


func _is_valid_frontline_anchor(unit: Node) -> bool:
    if unit == null or unit == self:
        return false
    if not unit.is_in_group(&"soldiers"):
        return false
    if unit.get("team_id") != team_id or unit.call("is_dead"):
        return false

    if frontline_anchor_excluded_archetype_name != "" and String(unit.get("unit_archetype_name")) == frontline_anchor_excluded_archetype_name:
        return false

    # Only follow allies that are true frontline combatants.
    # This prevents support units (e.g. drummer with 0 attack) from becoming anchors.
    if float(unit.get("attack_damage")) <= 0.0:
        return false

    return true


func _get_own_side_offset() -> float:
    return lane_player_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_enemy_side_offset


func _get_enemy_side_offset() -> float:
    return lane_enemy_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_player_side_offset


func take_damage(amount: float) -> void:
    if amount <= 0.0 or is_dead():
        return

    current_health = clampf(current_health - amount, 0.0, max_health)
    health_changed.emit(current_health, max_health)
    queue_redraw()

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
    if combat_state != CombatState.ATTACKING:
        _refresh_movement_target_for_mode()

    _process_leadership_support(delta)
    _update_targets_from_attack_overlap()

    match combat_state:
        CombatState.ATTACKING:
            _process_attacking(delta)
        CombatState.MOVING:
            _process_moving(delta)
        CombatState.IDLE:
            if _has_attack_target():
                _enter_attacking_state()

    # Keep debug/healthbar visuals responsive even when values change at runtime.
    queue_redraw()


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

    var effective_attack_damage: float = _get_effective_attack_damage()

    if _is_current_unit_target_attackable():
        if effective_attack_damage > 0.0:
            current_target_unit.call("take_damage", effective_attack_damage)
        return

    if _is_current_castle_target_attackable() and effective_attack_damage > 0.0:
        current_target_castle.take_damage(effective_attack_damage)


func _process_leadership_support(delta: float) -> void:
    if not provides_leadership:
        _clear_leadership_from_previous_targets()
        return

    if is_dead():
        _clear_leadership_from_previous_targets()
        return

    if leadership_kind == StringName() or leadership_bonus_amount <= 0.0:
        _clear_leadership_from_previous_targets()
        return

    var range_pixels: float = _get_leadership_radius_pixels()
    if range_pixels <= 0.0:
        _clear_leadership_from_previous_targets()
        return

    _leadership_refresh_remaining -= delta
    if _leadership_refresh_remaining > 0.0:
        return

    _leadership_refresh_remaining = leadership_refresh_interval_seconds

    var current_targets: Dictionary = {}
    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var unit: CombatUnit = node as CombatUnit
        if unit == null or unit == self or unit.team_id != team_id or unit.is_dead():
            continue

        if global_position.distance_to(unit.global_position) > range_pixels:
            continue

        unit.set_leadership_bonus_from_source(leadership_kind, self, leadership_bonus_amount)
        current_targets[str(unit.get_instance_id())] = unit

    for previous_key: Variant in _leadership_applied_targets.keys():
        if current_targets.has(previous_key):
            continue

        var previous_variant: Variant = _leadership_applied_targets.get(previous_key, null)
        if previous_variant == null or not is_instance_valid(previous_variant):
            continue

        var previous_obj: Object = previous_variant
        if previous_obj != null and previous_obj.has_method("clear_leadership_bonus_from_source"):
            previous_obj.call("clear_leadership_bonus_from_source", leadership_kind, self)

    _leadership_applied_targets = current_targets


func _clear_leadership_from_previous_targets() -> void:
    for unit_variant: Variant in _leadership_applied_targets.values():
        if unit_variant == null or not is_instance_valid(unit_variant):
            continue

        var unit_obj: Object = unit_variant
        if unit_obj != null and unit_obj.has_method("clear_leadership_bonus_from_source"):
            unit_obj.call("clear_leadership_bonus_from_source", leadership_kind, self)

    _leadership_applied_targets.clear()


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
    if _is_current_unit_target_attackable():
        return true

    current_target_unit = null

    if _is_current_castle_target_attackable():
        return true

    current_target_castle = null
    return false


func _update_targets_from_attack_overlap() -> void:
    if _attack_area == null:
        return

    current_target_unit = null
    current_target_castle = null

    for overlap_area: Area2D in _attack_area.get_overlapping_areas():
        if overlap_area == null:
            continue

        var overlap_parent: Node = overlap_area.get_parent()

        var unit: Node = overlap_parent
        if unit != null and unit.is_in_group(&"soldiers"):
            if unit == self or unit.get("team_id") == team_id or unit.call("is_dead"):
                continue
            if not _is_target_allowed_for_current_mode(unit.global_position, false):
                continue
            current_target_unit = unit
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


func _is_current_unit_target_attackable() -> bool:
    if current_target_unit == null or not is_instance_valid(current_target_unit):
        return false

    if current_target_unit == self or current_target_unit.get("team_id") == team_id or current_target_unit.call("is_dead"):
        return false

    if not _is_target_allowed_for_current_mode(current_target_unit.global_position, false):
        return false

    var hurtbox: Area2D = current_target_unit.call("get_hurtbox") as Area2D
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

    if is_castle_target and not can_attack_castles_in_defend:
        return false

    if not defend_limit_targets_near_own_castle:
        return true

    if own_castle == null or not is_instance_valid(own_castle):
        return true

    return own_castle.global_position.distance_to(target_global_position) <= defend_protection_radius_pixels


func _should_draw_health_bar() -> bool:
    if max_health <= 0.0 or is_dead():
        return false

    # Debug mode always forces visibility, even if show_health_bar is disabled per-unit.
    if debug_force_show_health_bar:
        return true

    if not show_health_bar:
        return false

    if show_health_bar_only_when_damaged and is_equal_approx(current_health, max_health):
        return false

    return true


func _get_leadership_aura_intensity() -> float:
    var full_bonus: float = maxf(0.001, leadership_aura_full_intensity_bonus)
    return clampf(get_total_leadership_bonus() / full_bonus, 0.0, 1.0)


func _draw() -> void:
    var leadership_intensity: float = _get_leadership_aura_intensity()
    if leadership_intensity > 0.0:
        var aura_radius: float = maxf(6.0, target_render_height * 0.38 + leadership_aura_radius_padding_pixels)
        var fill_color: Color = leadership_aura_color
        fill_color.a *= leadership_intensity
        var outline_color: Color = leadership_aura_outline_color
        outline_color.a *= leadership_intensity
        draw_circle(Vector2.ZERO, aura_radius, fill_color)
        draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 48, outline_color, leadership_aura_outline_width, true)

    if _should_draw_health_bar():
        # Draw the healthbar in scale-independent space so it remains visible/readable
        # even if the unit node itself is scaled.
        var sx: float = maxf(0.001, absf(scale.x))
        var sy: float = maxf(0.001, absf(scale.y))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / sx, 1.0 / sy))

        var health_ratio: float = clampf(current_health / maxf(0.001, max_health), 0.0, 1.0)
        var bar_width: float = health_bar_width_pixels
        var bar_height: float = health_bar_height_pixels
        var top_left: Vector2 = Vector2(-bar_width * 0.5, -target_render_height * 0.5 - health_bar_vertical_offset_pixels)
        var bar_rect: Rect2 = Rect2(top_left, Vector2(bar_width, bar_height))

        draw_rect(bar_rect, health_bar_bg_color, true)

        var fill_width: float = bar_width * health_ratio
        if fill_width > 0.0:
            draw_rect(Rect2(top_left, Vector2(fill_width, bar_height)), health_bar_fill_color, true)

        draw_rect(bar_rect, health_bar_border_color, false, 1.0)

        # Reset transform so any other debug draw (e.g. range) keeps expected behavior.
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if not debug_attack_range_visible:
        return

    if provides_leadership:
        var leadership_radius: float = _get_leadership_radius_pixels()
        if leadership_radius > 0.0:
            draw_circle(Vector2.ZERO, leadership_radius, debug_leadership_range_fill_color)
            draw_arc(
                Vector2.ZERO,
                leadership_radius,
                0.0,
                TAU,
                64,
                debug_leadership_range_outline_color,
                debug_leadership_range_outline_width,
                true
            )

    var radius: float = get_attack_range_radius_pixels()
    if radius <= 0.0:
        return

    draw_circle(Vector2.ZERO, radius, debug_range_fill_color)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, debug_range_outline_color, debug_range_outline_width, true)


func _update_world_position_from_offset() -> void:
    if lane_path == null or lane_curve == null:
        return

    var lane_local_position: Vector2 = lane_curve.sample_baked(current_offset, true)
    global_position = lane_path.to_global(lane_local_position) + Vector2(0.0, _formation_y_offset_pixels)


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

    circle_shape.radius = maxf(8.0, target_render_height * 0.22)


func _assign_formation_y_offset() -> void:
    if formation_y_spread_pixels <= 0.0:
        _formation_y_offset_pixels = 0.0
        return

    var slot_count: int = max(1, formation_y_slots)
    var sequence_index: int = _formation_spawn_counter
    _formation_spawn_counter += 1

    var slot_index: int = _get_center_out_slot_index(slot_count, sequence_index)
    if slot_count == 1:
        _formation_y_offset_pixels = 0.0
        return

    var t: float = float(slot_index) / float(slot_count - 1)
    _formation_y_offset_pixels = lerpf(-formation_y_spread_pixels, formation_y_spread_pixels, t)


func _get_center_out_slot_index(slot_count: int, sequence_index: int) -> int:
    if slot_count <= 1:
        return 0

    var center: int = int(floor(float(slot_count) / 2.0))
    var cycle_index: int = sequence_index % slot_count

    if cycle_index == 0:
        return center

    var step: int = int(ceil(float(cycle_index) / 2.0))
    if cycle_index % 2 == 1:
        return min(slot_count - 1, center + step)

    return max(0, center - step)


func _clamp_to_lane_bounds(offset_value: float) -> float:
    if lane_curve == null:
        return offset_value

    return clampf(offset_value, 0.0, lane_curve.get_baked_length())
