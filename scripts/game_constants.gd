class_name GameConstants
extends RefCounted

const TEAM_PLAYER: int = 0
const TEAM_ENEMY: int = 1

# Shared conversion factor for gameplay range units to world pixels.
const ATTACK_RANGE_UNIT_PIXELS: float = 48.0

# Physics layer bit used by damageable hurtboxes (Area2D). Keep this shared
# so every attacker can discover all valid damage targets consistently.
const COMBAT_HURTBOX_LAYER: int = 1 << 5
