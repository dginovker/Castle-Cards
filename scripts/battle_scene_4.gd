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
        # EXCEPTION: Still send woodcutters if 5+ wood and there's a grown tree near AI
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD and _has_fully_grown_tree_near_ai() and enemy_woodcutters < 1:
             _on_debug_spawn_enemy_woodcutter_pressed()
             return

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
        get_tree().create_timer(delay).timeout.connect(_on_ai_woodcutter_check.bind(offset))
    else:
        _on_ai_woodcutter_check(offset)

func _on_ai_woodcutter_check(tree_offset: float = 0.0) -> void:
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    # EXCEPTION: Still send woodcutters if 5+ wood and tree within 20% of AI castle
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD and tree_offset > lane_length * 0.8:
        _on_debug_spawn_enemy_woodcutter_pressed()
        return

    # Aggressive check: Don't buy woodcutters if we don't have military superiority
    if enemy_soldiers <= player_soldiers:
        return
        
    _on_debug_spawn_enemy_woodcutter_pressed()

func _has_fully_grown_tree_near_ai() -> bool:
    var curve: Curve2D = battle_lane_path.curve
    if curve == null: return false
    var lane_length: float = curve.get_baked_length()
    var threshold = lane_length * 0.8
    for tree in get_tree().get_nodes_in_group(&"trees"):
        if tree.get_meta("is_fully_grown", false):
            if tree.get_meta("lane_offset", 0.0) > threshold:
                return true
    return false
