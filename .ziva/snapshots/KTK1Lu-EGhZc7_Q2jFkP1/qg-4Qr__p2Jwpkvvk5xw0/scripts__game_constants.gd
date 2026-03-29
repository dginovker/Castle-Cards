class_name GameConstants
extends RefCounted

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

# Shared conversion factor for gameplay range units to world pixels.
const ATTACK_RANGE_UNIT_PIXELS: float = 48.0

# Soldier baseline stats from the game plan.
const SOLDIER_ATTACK_RANGE: float = 2.0
const SOLDIER_ATTACK_DAMAGE: float = 1.0
const SOLDIER_MAX_HEALTH: float = 3.0

# Archer baseline stats from the game plan.
const ARCHER_ATTACK_RANGE: float = 10.0
const ARCHER_ATTACK_DAMAGE: float = 2.0
const ARCHER_MAX_HEALTH: float = 2.0
const ARCHER_ATTACK_INTERVAL_SECONDS: float = 0.75

# Shared unit behavior modes.
const UNIT_MODE_ATTACK: int = 0
const UNIT_MODE_DEFEND: int = 1

# In Defend mode, soldiers only engage enemies near their own castle.
const SOLDIER_DEFEND_PROTECTION_RADIUS_PIXELS: float = 220.0

# Physics layer bit used by damageable hurtboxes (Area2D). Keep this shared
# so every attacker can discover all valid damage targets consistently.
const COMBAT_HURTBOX_LAYER: int = 1 << 5
