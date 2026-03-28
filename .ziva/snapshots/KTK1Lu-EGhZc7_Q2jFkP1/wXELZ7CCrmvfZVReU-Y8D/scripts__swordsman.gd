class_name Swordsman
extends AnimatedSprite2D

@export var move_speed: float = 110.0
@export var target_render_height: float = 48.0

@export_range(0.0, 100.0, 0.1) var attack_range: float = 2.0
@export_range(1.0, 256.0, 1.0) var attack_range_unit_pixels: float = 64.0
@export var debug_range_fill_color: Color = Color(1.0, 0.2, 0.2, 0.14)
@export var debug_range_outline_color: Color = Color(1.0, 0.2, 0.2, 0.9)
@export_range(1.0, 8.0, 0.1) var debug_range_outline_width: float = 2.0

var lane_path: Path2D
var lane_curve: Curve2D
var current_offset: float = 0.0
var target_offset: float = 0.0
var has_target: bool = false
var debug_attack_range_visible: bool = false


func _ready() -> void:
    add_to_group(&"soldiers")
    _apply_visual_scale()
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

    _update_world_position_from_offset()

    flip_h = target_offset < current_offset
    play(&"walk")
    set_process(true)


func set_debug_attack_range_visible(visible_state: bool) -> void:
    if debug_attack_range_visible == visible_state:
        return

    debug_attack_range_visible = visible_state
    queue_redraw()


func get_attack_range_radius_pixels() -> float:
    return maxf(0.0, attack_range * attack_range_unit_pixels)


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
