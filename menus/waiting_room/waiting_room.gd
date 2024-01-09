extends Control

@onready var player_list: ItemList  = $VBoxContainer/ItemList
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var world_scene_path: String = "res://scenes/world/world.tscn"

func _ready() -> void:
	_refresh_players(Network.players)
	if multiplayer.is_server():
		start_button.show()
	Network.player_connected.connect(_player_connected)

func _refresh_players(players: Dictionary) -> void:
	player_list.clear()
	for player_id: int in players:
		var player_name: String = players[player_id][Save.get_key_string_value(Save.SaveKey.PlayerName)]
		player_list.add_item(player_name, null, false)

func _player_connected() -> void:
	_refresh_players(Network.players)

func _on_start_button_pressed() -> void:
	Network.load_scene.rpc(world_scene_path)

