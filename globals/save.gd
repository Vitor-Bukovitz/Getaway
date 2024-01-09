extends Node

var save_data: Dictionary = {}
const SAVE_PATH: String = "user://save_data.json"

enum SaveKey {
	PlayerName
}

func _ready() -> void:
	get_data()

func get_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_value("Unnamed", SaveKey.PlayerName)
		save_game()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content: String = file.get_as_text()
	save_data = JSON.parse_string(content)
	file.close()

func save_game() -> void:
	var save: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save.store_line(JSON.stringify(save_data))

func get_value(key: SaveKey) -> Variant:
	var key_string: String = SaveKey.keys()[key]
	return save_data[key_string]

func save_value(value: Variant, key: SaveKey) -> void:
	var key_string: String = SaveKey.keys()[key]
	save_data[key_string] = value
	save_game()

func get_key_string_value(key: SaveKey) -> String:
	return SaveKey.keys()[key]
