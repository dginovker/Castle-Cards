class_name Swordsman
extends Sprite2D

@export var move_speed: float = 110.0

var lane_path: Path2D
var travel_distance: float = 0.0
var target_distance: float = 0.0
var has_target: bool = false


func _ready() -> void:
    set_process(false)


func setup_lane_travel(path: Path2D, start_distance: float, end_distance: float) -> void:
    lane_path = path

    if lane_path == null or lane_path.curve == null:
        has_target = false
        set_process(false)
        return

    var lane_length: float = lane_path.curve.get_baked_length()
    travel_distance = clampf(start_distance, 0.0, lane_length)
    target_distance = clampf(end_distance, 0.0, lane_length)

    has_target = true
    _update_position_from_lane()
    set_process(true)


func _process(delta: float) -> void:
    if not has_target:
        return

    if lane_path == null or lane_path.curve == null:
        set_process(false)
        return

    var direction: float = signf(target_distance - travel_distance)
    if is_zero_approx(direction):
        set_process(false)
        return

    travel_distance += direction * move_speed * delta

    var reached_target: bool = (
        (direction > 0.0 and travel_distance >= target_distance)
        or (direction < 0.0 and travel_distance <= target_distance)
    )

    if reached_target:
        travel_distance = target_distance
        has_target = false

    _update_position_from_lane()
    flip_h = direction < 0.0

    if reached_target:
        set_process(false)


func _update_position_from_lane() -> void:
    if lane_path == null or lane_path.curve == null:
        return

    var lane_position: Vector2 = lane_path.curve.sample_baked(travel_distance, true)
    global_position = lane_path.to_global(lane_position)
