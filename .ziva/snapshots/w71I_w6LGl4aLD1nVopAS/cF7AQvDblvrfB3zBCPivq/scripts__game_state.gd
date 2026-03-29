extends Node

signal trees_changed(new_count: int)
signal unit_unlocked(unit_type: String)

const SAVE_FILE = "user://castle_cards_save.json"

var trees: int = 0 :
    set(value):
        trees = value
        trees_changed.emit(trees)
        save_game()

var unlocked_units: Array[String] = ["swordsman", "woodcutter"]
var beaten_levels: Array[String] = []
var passive_income_upgrades: int = 0
var music_volume: float = 0.8

func _ready() -> void:
    load_game()
    # Initial set for volume in case MusicPlayer is already there
    var mp = get_node_or_null("/root/MusicPlayer")
    if mp:
        mp.set_volume(music_volume)

func _on_music_volume_changed(value: float) -> void:
    music_volume = value
    var mp = get_node_or_null("/root/MusicPlayer")
    if mp:
        mp.set_volume(music_volume)
    save_game()

func is_unit_unlocked(unit_type: String) -> bool:
    return unit_type in unlocked_units

func unlock_unit(unit_type: String, cost: int) -> bool:
    if trees >= cost and not is_unit_unlocked(unit_type):
        trees -= cost
        unlocked_units.append(unit_type)
        unit_unlocked.emit(unit_type)
        save_game()
        return true
    return false

func purchase_passive_income_upgrade() -> bool:
    var cost = get_passive_income_upgrade_cost()
    if trees >= cost:
        trees -= cost
        passive_income_upgrades += 1
        save_game()
        return true
    return false

func get_passive_income_upgrade_cost() -> int:
    return int(pow(2, passive_income_upgrades) * 2)

func get_current_passive_income_interval(base_interval: float) -> float:
    return maxf(0.5, base_interval - (passive_income_upgrades * 0.1))

func is_level_beaten(level_id: String) -> bool:
    return level_id in beaten_levels

func complete_level(level_id: String, reward: int) -> void:
    # Add trees regardless of whether the level was already beaten
    # But if it was already beaten, we update the trees value directly
    # The setter for trees calls save_game()
    trees += reward
    if not is_level_beaten(level_id):
        beaten_levels.append(level_id)
        save_game()

func save_game() -> void:
    var save_data = {
        "trees": trees,
        "unlocked_units": unlocked_units,
        "beaten_levels": beaten_levels,
        "passive_income_upgrades": passive_income_upgrades,
        "music_volume": music_volume
    }
    var json_string = JSON.stringify(save_data)
    var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return
        
    var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        if parse_result == OK:
            var data = json.get_data()
            if data is Dictionary:
                if data.has("trees"):
                    trees = int(data.get("trees"))
                if data.has("unlocked_units"):
                    unlocked_units.clear()
                    for unit in data.get("unlocked_units"):
                        unlocked_units.append(str(unit))
                if data.has("beaten_levels"):
                    beaten_levels.clear()
                    for level in data.get("beaten_levels"):
                        beaten_levels.append(str(level))
                if data.has("passive_income_upgrades"):
                    passive_income_upgrades = int(data.get("passive_income_upgrades"))
                if data.has("music_volume"):
                    music_volume = float(data.get("music_volume"))
                    var mp = get_node_or_null("/root/MusicPlayer")
                    if mp:
                        mp.set_volume(music_volume)

func wipe_save() -> void:
    # Set trees directly to avoid intermediate saves if we want
    # but the setter will call save_game anyway.
    # To be clean, we can just reset and save.
    trees = 0
    unlocked_units = ["swordsman", "woodcutter"]
    beaten_levels = []
    passive_income_upgrades = 0
    save_game()
