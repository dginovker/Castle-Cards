class_name Cannon
extends CombatUnit

# Cannon is a structure: it stays mounted at own castle in both modes.
func _get_attack_destination_offset() -> float:
    return _get_own_side_offset()


func _get_defend_destination_offset() -> float:
    return _get_own_side_offset()
