extends Node

signal trees_changed(new_count: int)
signal unit_unlocked(unit_type: String)

var trees: int = 50 :
    set(value):
        trees = value
        trees_changed.emit(trees)

var unlocked_units: Array[String] = ["swordsman", "woodcutter"]

func is_unit_unlocked(unit_type: String) -> bool:
    return unit_type in unlocked_units

func unlock_unit(unit_type: String, cost: int) -> bool:
    if trees >= cost and not is_unit_unlocked(unit_type):
        trees -= cost
        unlocked_units.append(unit_type)
        unit_unlocked.emit(unit_type)
        return true
    return false
