class_name Woodcutter
extends AnimatedSprite2D


enum WoodcutterState {
    SEARCHING_TREE,
    CHOPPING,
    RETURNING_WITH_LOG,
    RETURNING_EMPTY,
}

@export var team_id: int = GameConstants.TEAM_PLAYER
@export var move_speed: float = 64.0
@export_range(0.1, 1.0, 0.05) var carrying_speed_multiplier: float = 0.5
@export_range(0.1, 5.0, 0.1) var chop_pause_seconds: float = 1.0
@export var target_render_height: float = 44.0
@export var walk_empty_animation: StringName = &"walk_empty"
@export var walk_log_animation: StringName = &"walk_log"

var lane_path: Path2D
var lane_curve: Curve2D
var current_offset: float = 0.0
var lane_player_side_offset: float = 0.0
var lane_enemy_side_offset: float = 0.0

var _state: WoodcutterState = WoodcutterState.SEARCHING_TREE
var _chop_timer_remaining: float = 0.0
var _target_tree: Sprite2D
var _target_tree_offset: float = 0.0


func _ready() -> void:
    add_to_group(&"soldiers")
    _apply_visual_scale()
    stop()
    set_process(false)


func setup_lane_travel(path: Path2D, start_offset: float, _end_offset: float) -> void:
    lane_path = path
    lane_curve = path.curve if path != null else null

    if lane_curve == null:
        push_warning("Woodcutter.setup_lane_travel: Missing lane curve.")
        return

    current_offset = clampf(start_offset, 0.0, lane_curve.get_baked_length())
    _state = WoodcutterState.SEARCHING_TREE
    _chop_timer_remaining = 0.0
    _target_tree = null
    _target_tree_offset = current_offset
    _update_world_position_from_offset()
    _play_walk_animation_for_state()
    set_process(true)


func set_lane_side_offsets(player_side: float, enemy_side: float) -> void:
    lane_player_side_offset = player_side
    lane_enemy_side_offset = enemy_side


func set_debug_attack_range_visible(_visible_state: bool) -> void:
    # Woodcutter currently has no debug range visualization.
    pass


func is_dead() -> bool:
    return false


func _process(delta: float) -> void:
    if lane_curve == null:
        return

    match _state:
        WoodcutterState.SEARCHING_TREE:
            _process_searching_tree(delta)
        WoodcutterState.CHOPPING:
            _process_chopping(delta)
        WoodcutterState.RETURNING_WITH_LOG:
            _process_returning_with_log(delta)
        WoodcutterState.RETURNING_EMPTY:
            _process_returning_empty(delta)


func _process_searching_tree(delta: float) -> void:
    var closest_tree_ahead: Sprite2D = _find_first_fully_grown_tree_ahead()
    if closest_tree_ahead != null:
        _target_tree = closest_tree_ahead
        _target_tree_offset = _get_tree_lane_offset(_target_tree)

    if _is_target_tree_still_valid(_target_tree):
        _move_towards_offset(_target_tree_offset, move_speed, delta)
        if _is_offset_reached(_target_tree_offset):
            _begin_chopping(_target_tree)
        return

    _target_tree = null

    var enemy_offset: float = _get_enemy_side_offset()
    _move_towards_offset(enemy_offset, move_speed, delta)
    if _is_offset_reached(enemy_offset):
        _state = WoodcutterState.RETURNING_EMPTY
        _play_walk_animation_for_state()


func _process_returning_empty(delta: float) -> void:
    var own_offset: float = _get_own_side_offset()
    _move_towards_offset(own_offset, move_speed, delta)
    if _is_offset_reached(own_offset):
        _state = WoodcutterState.SEARCHING_TREE
        _target_tree = null
        _play_walk_animation_for_state()


func _begin_chopping(tree: Sprite2D) -> void:
    _state = WoodcutterState.CHOPPING
    _target_tree = tree
    _chop_timer_remaining = chop_pause_seconds
    stop()


func _process_chopping(delta: float) -> void:
    _chop_timer_remaining -= delta
    if _chop_timer_remaining > 0.0:
        return

    if _is_target_tree_still_valid(_target_tree):
        _target_tree.queue_free()

    _target_tree = null
    _state = WoodcutterState.RETURNING_WITH_LOG
    _play_walk_animation_for_state()


func _process_returning_with_log(delta: float) -> void:
    var own_offset: float = _get_own_side_offset()
    var carry_speed: float = maxf(1.0, move_speed * carrying_speed_multiplier)
    _move_towards_offset(own_offset, carry_speed, delta)

    if _is_offset_reached(own_offset):
        queue_free()


func _get_own_side_offset() -> float:
    return lane_player_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_enemy_side_offset


func _get_enemy_side_offset() -> float:
    return lane_enemy_side_offset if team_id == GameConstants.TEAM_PLAYER else lane_player_side_offset


func _get_direction_sign_to_enemy() -> float:
    return 1.0 if _get_enemy_side_offset() >= _get_own_side_offset() else -1.0


func _find_first_fully_grown_tree_ahead() -> Sprite2D:
    if lane_curve == null:
        return null

    var best_tree: Sprite2D
    var best_distance_ahead: float = INF
    var direction_sign: float = _get_direction_sign_to_enemy()

    for node: Node in get_tree().get_nodes_in_group(&"trees"):
        var tree: Sprite2D = node as Sprite2D
        if tree == null or not is_instance_valid(tree):
            continue
        if not bool(tree.get_meta("is_fully_grown", false)):
            continue

        var tree_offset: float = _get_tree_lane_offset(tree)
        var signed_distance_ahead: float = (tree_offset - current_offset) * direction_sign
        if signed_distance_ahead < -1.0:
            continue

        if signed_distance_ahead < best_distance_ahead:
            best_distance_ahead = signed_distance_ahead
            best_tree = tree

    return best_tree


func _get_tree_lane_offset(tree: Sprite2D) -> float:
    if tree.has_meta("lane_offset"):
        return float(tree.get_meta("lane_offset"))

    if lane_path == null or lane_curve == null:
        return 0.0

    var local_pos: Vector2 = lane_path.to_local(tree.global_position)
    return lane_curve.get_closest_offset(local_pos)


func _is_target_tree_still_valid(tree: Sprite2D) -> bool:
    if tree == null or not is_instance_valid(tree):
        return false
    return bool(tree.get_meta("is_fully_grown", false))


func _move_towards_offset(target: float, speed: float, delta: float) -> void:
    if lane_curve == null:
        return

    var lane_length: float = lane_curve.get_baked_length()
    var clamped_target: float = clampf(target, 0.0, lane_length)
    var previous_offset: float = current_offset
    current_offset = move_toward(current_offset, clamped_target, speed * delta)
    _update_world_position_from_offset()

    var moving_left: bool = current_offset < previous_offset
    var moving_right: bool = current_offset > previous_offset

    if moving_left:
        flip_h = true
    elif moving_right:
        flip_h = false


func _is_offset_reached(target: float) -> bool:
    return absf(current_offset - target) <= 0.75


func _update_world_position_from_offset() -> void:
    if lane_curve == null or lane_path == null:
        return

    var clamped_offset: float = clampf(current_offset, 0.0, lane_curve.get_baked_length())
    var lane_local_position: Vector2 = lane_curve.sample_baked(clamped_offset, true)
    global_position = lane_path.to_global(lane_local_position)


func _play_walk_animation_for_state() -> void:
    if sprite_frames == null:
        return

    var anim_to_play: StringName = walk_empty_animation
    if _state == WoodcutterState.RETURNING_WITH_LOG:
        anim_to_play = walk_log_animation

    if sprite_frames.has_animation(anim_to_play):
        play(anim_to_play)
    elif sprite_frames.has_animation(walk_empty_animation):
        play(walk_empty_animation)
    else:
        stop()


func _apply_visual_scale() -> void:
    if sprite_frames == null:
        return

    var animation_names: PackedStringArray = sprite_frames.get_animation_names()
    if animation_names.is_empty():
        return

    var first_animation: StringName = animation_names[0]
    if sprite_frames.get_frame_count(first_animation) <= 0:
        return

    var frame_texture: Texture2D = sprite_frames.get_frame_texture(first_animation, 0)
    if frame_texture == null:
        return

    var source_height: float = frame_texture.get_size().y
    if source_height <= 0.0:
        return

    var uniform_scale: float = target_render_height / source_height
    scale = Vector2(uniform_scale, uniform_scale)
