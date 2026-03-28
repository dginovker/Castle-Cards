class_name Swordsman
extends Sprite2D

@export var move_speed: float = 110.0

var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false


func _ready() -> void:
    set_process(false)


func set_target_position(new_target: Vector2) -> void:
    target_position = new_target
    has_target = true
    set_process(true)


func _process(delta: float) -> void:
    if not has_target:
        return

    global_position = global_position.move_toward(target_position, move_speed * delta)

    if global_position.distance_to(target_position) <= 1.0:
        global_position = target_position
        set_process(false)
