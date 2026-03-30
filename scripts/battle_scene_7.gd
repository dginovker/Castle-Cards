extends BattleSceneBase

const AI_WOOD_PER_TREE: int = 25
const AI_PASSIVE_INCOME_INTERVAL_SECONDS: float = 1.6

func _ready() -> void:
    level_id = "shores_level_7"
    super._ready()

    # AI Level 7 has the cannon unlock, so it starts with it.
    _spawn_cannon_for_team(GameConstants.TEAM_ENEMY, true)

    if _enemy_wood_income_timer != null:
        _enemy_wood_income_timer.wait_time = AI_PASSIVE_INCOME_INTERVAL_SECONDS
        if _enemy_wood_income_timer.is_stopped():
            _enemy_wood_income_timer.start()

func _on_wood_delivered(team: int, amount: int) -> void:
    if team == GameConstants.TEAM_ENEMY:
        _add_wood(team, AI_WOOD_PER_TREE)
        return

    _add_wood(team, amount + (GameState.get_tree_yield_bonus_per_tree() if team == GameConstants.TEAM_PLAYER else 0))

func _update_ai() -> void:
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)
    var enemy_woodcutters = _get_unit_count(Woodcutter, GameConstants.TEAM_ENEMY)

    # Level 4 aggression behavior copied for Shores Level 5.
    if enemy_soldiers <= player_soldiers:
        # Exception: allow one woodcutter if a grown tree is near AI.
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD and _has_fully_grown_tree_near_ai() and enemy_woodcutters < 1:
            _on_debug_spawn_enemy_woodcutter_pressed()
            return

        if _enemy_wood >= 25:
            _on_debug_spawn_enemy_swordsman_pressed()
            _on_debug_spawn_enemy_archer_pressed()
        elif _enemy_wood >= 10:
            _on_debug_spawn_enemy_swordsman_pressed()
        return

    # If we have a military lead, push wood economy hard.
    if enemy_soldiers >= player_soldiers + 2 and enemy_woodcutters < 5:
        if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD:
            _on_debug_spawn_enemy_woodcutter_pressed()
        return

    # Standard aggressive spawn at 10 wood.
    if _enemy_wood >= 25:
        _on_debug_spawn_enemy_swordsman_pressed()
        _on_debug_spawn_enemy_archer_pressed()
    elif _enemy_wood >= 10:
        _on_debug_spawn_enemy_swordsman_pressed()

func _on_tree_growing(offset: float) -> void:
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()

    var delay: float = 1.0
    if offset < lane_length / 2:
        delay = 0.0
    elif offset > lane_length * 0.9:
        delay = 2.5

    if delay > 0.0:
        get_tree().create_timer(delay).timeout.connect(_on_ai_woodcutter_check.bind(offset))
    else:
        _on_ai_woodcutter_check(offset)

func _on_ai_woodcutter_check(tree_offset: float = 0.0) -> void:
    var player_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_PLAYER)
    var enemy_soldiers = _get_soldier_count_excluding_woodcutters(GameConstants.TEAM_ENEMY)

    # Exception: send woodcutter if tree is very close to AI side.
    var curve: Curve2D = battle_lane_path.curve
    var lane_length: float = curve.get_baked_length()
    if _enemy_wood >= GameConstants.WOODCUTTER_COST_WOOD and tree_offset > lane_length * 0.8:
        _on_debug_spawn_enemy_woodcutter_pressed()
        return

    # Don't buy woodcutters without military superiority.
    if enemy_soldiers <= player_soldiers:
        return

    _on_debug_spawn_enemy_woodcutter_pressed()

func _has_fully_grown_tree_near_ai() -> bool:
    var curve: Curve2D = battle_lane_path.curve
    if curve == null:
        return false

    var lane_length: float = curve.get_baked_length()
    var threshold: float = lane_length * 0.8
    for tree: Node in get_tree().get_nodes_in_group(&"trees"):
        if tree.get_meta("is_fully_grown", false):
            if tree.get_meta("lane_offset", 0.0) > threshold:
                return true
    return false
