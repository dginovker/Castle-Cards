class_name Cannon
extends CombatUnit

# Cannon is a structure: it stays mounted near its own castle.
func _get_attack_destination_offset() -> float:
    return _get_own_side_offset()
