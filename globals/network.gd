extends Node

signal player_connected
signal player_disconnected

@export var default_ip: String = "127.0.0.1"
@export var default_port: int = 32032
@export var max_players: int = 4

var players: Dictionary = {}
var local_player_id: int = 0
var ready_players: int = 0

func start_network(host: bool) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if host:
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		_add_to_player_list()
		peer.create_server(default_port, max_players)
	else:
		multiplayer.connected_to_server.connect(_server_connected)
		peer.create_client(default_ip, default_port)
	multiplayer.multiplayer_peer = peer

func _add_to_player_list() -> void:
	local_player_id = multiplayer.get_unique_id()
	players[local_player_id] = Save.save_data
	player_connected.emit()
	_send_player_info.rpc(local_player_id, players[local_player_id])

# Host
func _peer_disconnected(id: int) -> void:
	players[id] = null
	_send_player_info.rpc(id, null)

# Client
func _server_connected() -> void:
	_add_to_player_list()

@rpc("authority", "call_local", "reliable")
func load_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

# Update Players Data
@rpc("any_peer", "call_remote", "reliable")
func _send_player_info(id: int, player_data: Dictionary) -> void:
	players[id] = player_data
	if multiplayer.is_server():
		_sync_new_players.rpc(players)
	if player_data != null:
		player_connected.emit()
	else:
		player_disconnected.emit()

@rpc("authority", "call_remote", "reliable")
func _sync_new_players(sync_players: Dictionary) -> void:
	players = sync_players
	player_connected.emit()



