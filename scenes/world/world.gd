extends Node3D

@onready var player_resource: PackedScene = preload("res://entities/player/player.tscn")
@onready var players: Node3D = $MultiplayerSpawner/Players
@onready var ui: Control = $UI
@onready var grid_map: WorldGridMap = $GridMap

func _enter_tree() -> void:
	get_tree().paused = true

func _ready() -> void:
	if multiplayer.is_server():
		_send_ready.rpc()

func _spawn_player() -> void:
	var new_player: Node = player_resource.instantiate()
	new_player.name = str(Network.local_player_id)
	players.add_child(new_player)

func _unpause() -> void:
	get_tree().paused = false
	ui.visible = false

@rpc("authority", "call_local", "reliable")
func _all_players_ready() -> void:
	_unpause()
	if multiplayer.is_server():
		_spawn_player()
	else:
		_spawn_remote_player.rpc(str(Network.local_player_id))

@rpc("any_peer", "call_remote", "reliable")
func _spawn_remote_player(id: String) -> void:
	if multiplayer.is_server():
		var new_player: Node = player_resource.instantiate()
		new_player.name = id
		players.add_child(new_player)

@rpc("any_peer", "call_local", "reliable")
func _send_ready() -> void:
	if multiplayer.is_server():
		_player_ready()
	else:
		_player_ready.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _player_ready() -> void:
	Network.ready_players += 1
	if Network.ready_players == Network.players.size():
		_all_players_ready.rpc()
