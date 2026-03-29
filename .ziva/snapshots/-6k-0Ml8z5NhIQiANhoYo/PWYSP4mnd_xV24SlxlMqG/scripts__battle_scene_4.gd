extends BattleSceneBase

func _ready() -> void:
    level_id = "level_4"
    super._ready()

func _update_ai() -> void:
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)
    var enemy_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_ENEMY)
    
    # NEW Level 4 Aggression: 
    # If fewer or equal soldiers than player, ONLY buy soldiers.
    # At start (0 vs 0), this forces the AI to save for a soldier first.
    if enemy_soldiers <= player_soldiers:
        if _enemy_wood >= 10:
            _on_debug_spawn_enemy_swordsman_pressed()
        return

    # If we have a military lead:
    # Level 3 Logic: Woodcutter spam if we have a big lead
    if enemy_soldiers >= player_soldiers + 2 and enemy_woodcutters < 5:
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD:
            _on_debug_spawn_enemy_woodcutter_pressed()
        return

    # Standard aggressive spawn at 10 wood
    if _enemy_wood >= 10:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(offset: float) -> void:
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    
    var delay = 1.0 
    if offset < lane_length / 2: 
        delay = 0.0 
    elif offset > lane_length * 0.9: 
        delay = 2.5 
        
    if delay > 0:
        get_tree().create_timer(delay).timeout.connect(_on_ai_woodcutter_check)
    else:
        _on_ai_woodcutter_check()

func _on_ai_woodcutter_check() -> void:
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    # Aggressive check: Don't buy woodcutters if we don't have military superiority
    if enemy_soldiers <= player_soldiers:
        return
        
    _on_debug_spawn_enemy_woodcutter_pressed()
