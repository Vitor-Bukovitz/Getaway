class_name ObjectSpawner

extends Node3D

@export var gridmap: WorldGridMap
@export_range(0, 100) var percentage_of_parked_cars: float = 25
var parked_cars: PackedScene = preload("res://scenes/props/parked_cars.tscn")

var tiles: Array[Vector3] = []
var map_size: Vector2 = Vector2()

var number_of_parked_cars: int = 0

func generate_props(tile_list: Array[Vector3], size: Vector2) -> void:
	tiles = tile_list
	number_of_parked_cars = int(len(tile_list) * (percentage_of_parked_cars / 100))
	map_size = size
	_place_cars()

func _random_tiles(tile_count: int) -> Array[Vector3]:
	var tile_list: Array[Vector3] = tiles
	tile_list.pop_front()
	var selected_tiles: Array[Vector3] = tile_list
	tile_list.shuffle()
	for i: int in range(tile_count):
		var tile: Vector3 = tile_list[i]
		selected_tiles.append(tile)
	return selected_tiles

func _place_cars() -> void:
	var tile_list: Array[Vector3] = _random_tiles(number_of_parked_cars)
	for i: int in range(number_of_parked_cars):
		var tile: Vector3 = tile_list[0]
		var tile_type: int = gridmap.get_cell_item_from_position(tile)
		var allowed_rotation: Array[int] = _lookup_rotation(tile_type)
		if allowed_rotation.size() > 0:
			var tile_rotation: int = allowed_rotation[randi() % allowed_rotation.size() - 1] * -1
			tile.y = tile.y + 1.2
			_spawn_cars.rpc(tile, tile_rotation)
		tile_list.pop_front()

@rpc("authority", "call_local", "reliable")
func _spawn_cars(tile: Vector3, car_rotation: int) -> void:
	var parked_cars_node: Node3D = parked_cars.instantiate()
	parked_cars_node.position = Vector3((tile.x * 10) + 5, tile.y, (tile.z * 10) + 5)
	parked_cars_node.rotation_degrees.y = car_rotation # + 270
	add_child(parked_cars_node, true)

func _lookup_rotation(tile_item: int) -> Array[int]:
	var rotations: Array[int] = []
	match tile_item:
		1, 3, 5, 7, 9, 11, 13:
			rotations.append(0)
		2, 3, 6, 7, 10, 11, 14:
			rotations.append(90)
		4, 5, 6, 7, 12, 13, 14:
			rotations.append(180)
		8, 9, 10, 11, 12, 13, 14:
			rotations.append(270)
	return rotations
