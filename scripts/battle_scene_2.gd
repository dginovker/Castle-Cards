extends BattleSceneBase

func _ready() -> void:
    level_id = "level_2"
    super._ready()

func _update_ai() -> void:
    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)
    
    # Logic 3: If the player has 2 woodcutters but no soldiers AND the AI has no soldiers, 
    # the AI should not buy woodcutters and instead buy a soldier as soon as it hits 10 wood.
    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        if _enemy_wood >= 10:
             _on_debug_spawn_enemy_swordsman_pressed()
        return # Important: skip woodcutter and normal soldier logic in this state
        
    # Logic 2: If we have 15+ resources, spawn a swordsman
    if _enemy_wood >= 15:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(offset: float) -> void:
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    
    var delay = 1.0 # Default
    if offset < lane_length / 2: # Player half (closer to player)
        delay = 0.0 # Instant
    elif offset > lane_length * 0.9: # within 10% of the path closest to the AI castle
        delay = 2.0
        
    if delay > 0:
        get_tree().create_timer(delay).timeout.connect(_on_ai_woodcutter_check)
    else:
        _on_ai_woodcutter_check()

func _on_ai_woodcutter_check(tree_offset: float = 0.0) -> void:
    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    # Logic 3: "...the AI should not buy woodcutters..."
    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        return
        
    # Level 2 has no cap on woodcutters, so we just spawn one
    _on_debug_spawn_enemy_woodcutter_pressed()
