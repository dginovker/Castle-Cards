class_name GameConstants
extends RefCounted

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

# Shared conversion factor for gameplay range units to world pixels.
const ATTACK_RANGE_UNIT_PIXELS: float = 8.0

# Soldier baseline stats from the game plan.
const SOLDIER_ATTACK_RANGE: float = 2.0
const SOLDIER_ATTACK_DAMAGE: float = 1.0
const SOLDIER_MAX_HEALTH: float = 3.0

# Archer baseline stats from the game plan.
const ARCHER_ATTACK_RANGE: float = 10.0
const ARCHER_ATTACK_DAMAGE: float = 2.0
const ARCHER_MAX_HEALTH: float = 2.0
const ARCHER_ATTACK_INTERVAL_SECONDS: float = 0.75

# Drummer baseline stats from the game plan.
const DRUMMER_ATTACK_RANGE: float = 0.0
const DRUMMER_ATTACK_DAMAGE: float = 0.0
const DRUMMER_MAX_HEALTH: float = 5.0
const DRUMMER_LEADERSHIP_RANGE: float = 4.0
const DRUMMER_LEADERSHIP_BONUS: float = 0.5

# Cannon (tower-like structure) baseline stats.
const CANNON_ATTACK_RANGE: float = 5.0
const CANNON_ATTACK_DAMAGE: float = 1.0
const CANNON_MAX_HEALTH: float = 1.0

# Economy tuning.
const STARTING_WOOD: int = 20
const WOOD_PASSIVE_INCOME_AMOUNT: int = 1
const WOOD_PASSIVE_INCOME_INTERVAL_SECONDS: float = 2.0
const WOODCUTTER_DELIVERY_WOOD: int = 15

# Unit spawn costs (latest balance pass from gameplay request).
const WOODCUTTER_COST_WOOD: int = 5
const SWORDSMAN_COST_WOOD: int = 10
const ARCHER_COST_WOOD: int = 15
const DRUMMER_COST_WOOD: int = 20
const CANNON_COST_WOOD: int = 40

# Physics layer bit used by damageable hurtboxes (Area2D). Keep this shared
# so every attacker can discover all valid damage targets consistently.
const COMBAT_HURTBOX_LAYER: int = 1 << 5
