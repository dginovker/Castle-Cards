class_name Swordsman
extends AnimatedSprite2D

@export var move_speed: float = 110.0
@export var target_render_height: float = 48.0

var lane_path: Path2D
var lane_curve: Curve2D
var current_offset: float = 0.0
var target_offset: float = 0.0
var has_target: bool = false


func _ready() -> void:
    _apply_visual_scale()
    stop()
    set_process(false)


func setup_lane_travel(path: Path2D, start_offset: float, end_offset: float) -> void:
    lane_path = path
    lane_curve = path.curve if path != null else null

    if lane_curve == null:
        push_warning("Swordsman.setup_lane_travel: Missing lane curve.")
        return

    current_offset = start_offset
    target_offset = end_offset
    has_target = true

    _update_world_position_from_offset()

    flip_h = target_offset < current_offset
    play(&"walk")
    set_process(true)


func _process(delta: float) -> void:
    if not has_target or lane_curve == null:
        return

    current_offset = move_toward(current_offset, target_offset, move_speed * delta)
    _update_world_position_from_offset()

    if is_equal_approx(current_offset, target_offset) or absf(current_offset - target_offset) <= 0.5:
        current_offset = target_offset
        _update_world_position_from_offset()
        has_target = false
        stop()
        set_process(false)


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
