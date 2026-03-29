extends BattleSceneBase

var _has_spawned_initial_soldier: bool = false

func _ready() -> void:
    level_id = "level_4"
    super._ready()

func _update_ai() -> void:
    if not _has_spawned_initial_soldier:
        if _enemy_wood >= GameConstants.SWORDSMAN_COST_WOOD:
            _on_debug_spawn_enemy_swordsman_pressed()
            _has_spawned_initial_soldier = true
        return # Do nothing else until initial soldier is spawned

    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)
    var enemy_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_ENEMY)
    
    # Level 3 Logic: Woodcutter spam
    if enemy_soldiers >= player_soldiers + 2 and enemy_woodcutters < 5:
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD:
            _on_debug_spawn_enemy_woodcutter_pressed()
        return

    # Counter-play logic
    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        if _enemy_wood >= 10:
             _on_debug_spawn_enemy_swordsman_pressed()
        return 
        
    # Standard aggressive spawn
    if _enemy_wood >= 10:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(offset: float) -> void:
    if not _has_spawned_initial_soldier:
        return # Don't even start timers for woodcutters until initial soldier is out

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
    if not _has_spawned_initial_soldier:
        return

    var player_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_PLAYER)
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    if player_woodcutters >= 2 and player_soldiers == 0 and enemy_soldiers == 0:
        return
        
    _on_debug_spawn_enemy_woodcutter_pressed()
