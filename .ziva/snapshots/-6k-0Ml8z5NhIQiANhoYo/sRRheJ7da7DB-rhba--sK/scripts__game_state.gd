extends Node

signal trees_changed(new_count: int)
signal unit_unlocked(unit_type: String)

var trees: int = 50 :
    set(value):
        trees = value
        trees_changed.emit(trees)

var unlocked_units: Array[String] = ["swordsman", "woodcutter"]
var beaten_levels: Array[String] = []

func is_unit_unlocked(unit_type: String) -> bool:
    return unit_type in unlocked_units

func unlock_unit(unit_type: String, cost: int) -> bool:
    if trees >= cost and not is_unit_unlocked(unit_type):
        trees -= cost
        unlocked_units.append(unit_type)
        unit_unlocked.emit(unit_type)
        return true
    return false

func is_level_beaten(level_id: String) -> bool:
    return level_id in beaten_levels

func complete_level(level_id: String, reward: int) -> void:
    trees += reward
    if not is_level_beaten(level_id):
        beaten_levels.append(level_id)
