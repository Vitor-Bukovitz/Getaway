extends Node3D

@onready var player_resource: PackedScene = preload("res://entities/player/player.tscn")
@onready var players: Node3D = $MultiplayerSpawner/Players
@onready var ui: Control = $UI
@onready var grid_map: WorldGridMap = $GridMap

func _ready():
	player_ready.rpc_id(1)

func _spawn_player() -> void:
	var new_player: Node = player_resource.instantiate()
	new_player.name = str(Network.local_player_id)
	players.add_child(new_player)

func _unpause() -> void:
	get_tree().paused = false
	ui.visible = false

func _all_players_ready() -> void:
	_unpause()
	if multiplayer.is_server():
		_spawn_player()
		grid_map.create_map()
	else:
		spawn_remote_player.rpc(str(Network.local_player_id))

@rpc("any_peer", "call_remote", "reliable")
func spawn_remote_player(id: String) -> void:
	if multiplayer.is_server():
		var new_player: Node = player_resource.instantiate()
		new_player.name = id
		players.add_child(new_player)

@rpc("any_peer", "call_local", "reliable")
func player_ready() -> void:
	if multiplayer.is_server():
		print("+1 ready!")
		Network.ready_players += 1
		print("total ready: " + str(Network.ready_players))
		if Network.ready_players == Network.players.size():
			print("starting game...")
			all_players_ready.rpc()

@rpc("any_peer", "call_local", "reliable")
func all_players_ready() -> void:
	_all_players_ready.call_deferred()


