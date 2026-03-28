class_name Archer
extends Swordsman

@export_range(0.0, 1000.0, 1.0) var frontline_follow_distance_pixels: float = 56.0
@export_range(0.0, 1000.0, 1.0) var defend_retreat_distance_pixels: float = 84.0


func _ready() -> void:
    attack_range = GameConstants.ARCHER_ATTACK_RANGE
    attack_damage = GameConstants.ARCHER_ATTACK_DAMAGE
    max_health = GameConstants.ARCHER_MAX_HEALTH
    attack_interval_seconds = GameConstants.ARCHER_ATTACK_INTERVAL_SECONDS

    super._ready()
    add_to_group(&"archers")


func _process(delta: float) -> void:
    if combat_state != CombatState.ATTACKING:
        _refresh_movement_target_for_mode()

    super._process(delta)


func _get_mode_destination_offset() -> float:
    if lane_curve == null:
        return target_offset

    if active_mode == GameConstants.UNIT_MODE_DEFEND:
        return _get_defend_destination_offset()

    return _get_attack_destination_offset()


func _get_attack_destination_offset() -> float:
    var enemy_side_offset: float = _get_enemy_side_offset()
    var result: Dictionary = _find_frontline_non_archer_offset()

    if not result.get("found", false):
        return enemy_side_offset

    var frontline_offset: float = result.get("offset", enemy_side_offset)
    var desired_offset: float = (
        frontline_offset - frontline_follow_distance_pixels
        if team_id == GameConstants.TEAM_PLAYER
        else frontline_offset + frontline_follow_distance_pixels
    )

    return _clamp_to_lane_bounds(desired_offset)


func _get_defend_destination_offset() -> float:
    var own_side_offset: float = _get_own_side_offset()
    var desired_offset: float = (
        own_side_offset - defend_retreat_distance_pixels
        if team_id == GameConstants.TEAM_PLAYER
        else own_side_offset + defend_retreat_distance_pixels
    )

    return _clamp_to_lane_bounds(desired_offset)


func _find_frontline_non_archer_offset() -> Dictionary:
    if lane_curve == null or lane_path == null:
        return {"found": false, "offset": 0.0}

    var found: bool = false
    var selected_offset: float = 0.0

    for node: Node in get_tree().get_nodes_in_group(&"soldiers"):
        var unit: Swordsman = node as Swordsman
        if unit == null or unit == self:
            continue
        if unit.team_id != team_id or unit.is_dead():
            continue
        if unit is Archer:
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


func _is_target_allowed_for_current_mode(target_global_position: Vector2, is_castle_target: bool) -> bool:
    if active_mode != GameConstants.UNIT_MODE_DEFEND:
        return super._is_target_allowed_for_current_mode(target_global_position, is_castle_target)

    return not is_castle_target


func _clamp_to_lane_bounds(offset_value: float) -> float:
    if lane_curve == null:
        return offset_value

    return clampf(offset_value, 0.0, lane_curve.get_baked_length())
