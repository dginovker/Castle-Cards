class_name Castle
extends Sprite2D

signal health_changed(current_health: float, max_health: float)
signal destroyed(castle: Castle)

@export var team_id: int = GameConstants.TEAM_PLAYER
@export_range(1.0, 10000.0, 1.0) var max_health: float = 20.0

@export var debug_hurtbox_fill_color: Color = Color(0.2, 0.8, 1.0, 0.14)
@export var debug_hurtbox_outline_color: Color = Color(0.2, 0.8, 1.0, 0.9)
@export_range(1.0, 8.0, 0.1) var debug_hurtbox_outline_width: float = 2.0

var current_health: float = 0.0

var _hurtbox_area: Area2D
var _hurtbox_shape_node: CollisionShape2D
var _debug_hurtbox_visible: bool = false


func _ready() -> void:
    add_to_group(&"castles")
    current_health = max_health
    _ensure_hurtbox()
    _refresh_hurtbox_shape()
    health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
    if amount <= 0.0 or is_destroyed():
        return

    current_health = clampf(current_health - amount, 0.0, max_health)
    health_changed.emit(current_health, max_health)

    if is_zero_approx(current_health):
        destroyed.emit(self)


func is_destroyed() -> bool:
    return current_health <= 0.0


func get_hurtbox() -> Area2D:
    return _hurtbox_area


func set_debug_hurtbox_visible(visible_state: bool) -> void:
    if _debug_hurtbox_visible == visible_state:
        return

    _debug_hurtbox_visible = visible_state
    queue_redraw()


func _draw() -> void:
    if not _debug_hurtbox_visible:
        return

    var rect_shape: RectangleShape2D = _hurtbox_shape_node.shape as RectangleShape2D if _hurtbox_shape_node != null else null
    if rect_shape == null:
        return

    var hurtbox_rect: Rect2 = Rect2(_hurtbox_shape_node.position - (rect_shape.size * 0.5), rect_shape.size)
    draw_rect(hurtbox_rect, debug_hurtbox_fill_color, true)
    draw_rect(hurtbox_rect, debug_hurtbox_outline_color, false, debug_hurtbox_outline_width)


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

    if not (_hurtbox_shape_node.shape is RectangleShape2D):
        _hurtbox_shape_node.shape = RectangleShape2D.new()


func _refresh_hurtbox_shape() -> void:
    if texture == null or _hurtbox_shape_node == null:
        return

    var rect_shape: RectangleShape2D = _hurtbox_shape_node.shape as RectangleShape2D
    if rect_shape == null:
        rect_shape = RectangleShape2D.new()
        _hurtbox_shape_node.shape = rect_shape

    var texture_size: Vector2 = texture.get_size()
    rect_shape.size = texture_size

    if centered:
        _hurtbox_shape_node.position = offset
    else:
        _hurtbox_shape_node.position = offset + (texture_size * 0.5)

    queue_redraw()
