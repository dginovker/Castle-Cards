extends BattleSceneBase

func _ready() -> void:
    level_id = "level_1"
    super._ready()

func _update_ai() -> void:
    # Logic 2: If we have 15+ resources, spawn a swordsman
    if _enemy_wood >= 15:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(_offset: float) -> void:
    # Level 1 AI: 1 second after a tree is growing...
    get_tree().create_timer(1.0).timeout.connect(_on_ai_woodcutter_check)

func _on_ai_woodcutter_check() -> void:
    # Logic 1: if we do not have a woodcutter on the field, spawn a woodcutter
    if _get_enemy_woodcutter_count() == 0:
        _on_debug_spawn_enemy_woodcutter_pressed()
