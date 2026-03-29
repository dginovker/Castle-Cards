extends BattleSceneBase

func _ready() -> void:
    level_id = "level_3"
    super._ready()

func _update_ai() -> void:
    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)
    var enemy_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_ENEMY)
    
    # Logic 1: Woodcutter spam (New to Level 3)
    # if the AI ever has 2 more swordsmen on the field than the player AND has less than 5 woodcutters active, 
    # it spam buys woodcutters (regardless of whether or not there's wood on the field)
    if enemy_soldiers >= player_soldiers + 2 and enemy_woodcutters < 5:
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD:
            _on_debug_spawn_enemy_woodcutter_pressed()
        return # Skip other logic while spamming woodcutters

    # Logic from Level 2: Counter-play
    # If the player has 2 woodcutters but no soldiers AND the AI has no soldiers, 
    # the AI should not buy woodcutters and instead buy a soldier as soon as it hits 10 wood.
    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        if _enemy_wood >= 10:
             _on_debug_spawn_enemy_swordsman_pressed()
        return 
        
    # Logic 2: Spawn swordsman at 10 wood (Modified from Level 2's 15)
    if _enemy_wood >= 10:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(offset: float) -> void:
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    
    var delay = 1.0 # Default
    if offset < lane_length / 2: # Player half (closer to player)
        delay = 0.0 # Instant
    elif offset > lane_length * 0.9: # within 10% of the path closest to the AI castle
        delay = 2.5 # Increased from Level 2's 2.0s to match growth
        
    if delay > 0:
        get_tree().create_timer(delay).timeout.connect(_on_ai_woodcutter_check)
    else:
        _on_ai_woodcutter_check()

func _on_ai_woodcutter_check(_tree_offset: float = 0.0) -> void:
    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    # Logic from Level 2: "...the AI should not buy woodcutters..."
    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        return
        
    # No woodcutter cap
    _on_debug_spawn_enemy_woodcutter_pressed()
