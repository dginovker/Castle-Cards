extends HBoxContainer

@onready var value_label: Label = %ValueLabel

func _ready() -> void:
    _update_display(get_node("/root/GameState").trees)
    get_node("/root/GameState").trees_changed.connect(_update_display)

func _update_display(new_value: int) -> void:
    value_label.text = str(new_value)
