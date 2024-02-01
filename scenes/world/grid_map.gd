class_name WorldGridMap

extends GridMap

const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8
const WIDTH: int = 20
const HEIGHT: int = 20
const SPACING: int = 2

var erase_fraction: float = 0.25
var building_locations: Array[Vector3] = []

var cell_walls: Dictionary = {
	Vector3(0, 0, -SPACING): N,
	Vector3(SPACING, 0, 0): E,
	Vector3(0, 0, SPACING): S,
	Vector3(-SPACING, 0, 0): W
}

func _ready() -> void:
	clear()
	if multiplayer.is_server():
		randomize()
		_make_empty_map()
		_make_map()
		_adjust_building_rotations()
		_erase_walls()

#region Map Creation
func _make_empty_map() -> void:
	var possible_rotations: Array[int] = [0, 10, 16, 22]
	for x: int in range(0, WIDTH - 1):
		for z: int in range(0, HEIGHT - 1):
			var building_rotation: int = possible_rotations[randi() % 4]
			var building: int = _pick_building()
			building_locations.append(Vector3(x, 0, z))
			_place_cell.rpc(Vector3i(x, 0, z), building, building_rotation)
	
	# Add map border
	for x: int in range(-1, WIDTH):
		var building: int = _pick_building()
		_place_cell.rpc(Vector3i(x, 0, -1), building, 0)
		_place_cell.rpc(Vector3i(-1, 0, x), building, 16)
		_place_cell.rpc(Vector3i(WIDTH - 1, 0, x), building, 22)
		_place_cell.rpc(Vector3i(x, 0, WIDTH - 1), building, 10)

func _pick_building() -> int:
	var possible_buildings: Array[int] = [6, 7, 8, 9, 10, 11, 12, 13]
	return possible_buildings[randi() % possible_buildings.size() - 1]

func _make_map() -> void:
	var unvisited: Array[Vector3] = []
	var stack: Array[Vector3] = []
	for x: int in range(0, WIDTH, SPACING):
		for z: int in range(0, HEIGHT, SPACING):
			unvisited.append(Vector3(x, 0, z))
	
	var current: Vector3 = Vector3(0, 0, 0)
	unvisited.erase(current)
	
	while unvisited:
		var neighbors: Array[Vector3] = _check_neighbors(current, unvisited)
		if neighbors:
			stack.append(current)
			
			var next: Vector3 = neighbors[randi() % neighbors.size()]
			if current == Vector3(0, 0, 0):
				building_locations.erase(Vector3(0, 0, 0))
				next = Vector3(0, 0, SPACING)
			var direction: Vector3 = next - current
			
			var current_walls: int = _get_cell_item_from_position(current) - cell_walls[direction]
			var next_walls: int = _get_cell_item_from_position(next) - cell_walls[-direction]
			
			_place_cell.rpc(current, _get_cell_item(current_walls), _get_cell_rotation(current_walls))
			_place_cell.rpc(next, _get_cell_item(next_walls), _get_cell_rotation(next_walls))
			_fill_gaps(current, direction)
			
			current = next
			unvisited.erase(current)
			building_locations.erase(Vector3(current.x, 0, current.z))
		elif stack:
			current = stack.pop_back()

func _adjust_building_rotations() -> void:
	for location: Vector3 in building_locations:
		var road_direction: Vector3 = _find_nearest_road_direction(location)
		if road_direction != Vector3.ZERO:
			var new_rotation: int = _calculate_rotation_towards_road(road_direction)
			var item: int = get_cell_item(location)
			_place_cell.rpc(location, item, new_rotation)

func _find_nearest_road_direction(building_location: Vector3) -> Vector3:
	# Define the search directions (N, W, S, E)
	var directions: Array = [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)]
	
	for direction: Vector3 in directions:
		var neighbor_location: Vector3 = building_location + direction
		if _is_road(neighbor_location):
			return direction
	
	return Vector3.ZERO  # Return a default value if no road is found

func _is_road(location: Vector3) -> bool:
	var cell: int = get_cell_item(location)
	# You need to define what cell item number represents a road
	return cell <= 5  # Replace ROAD_CELL_TYPE with the actual value for roads

func _calculate_rotation_towards_road(road_direction: Vector3) -> int:
	if road_direction == Vector3(0, 0, -1):  # North
		return 10  # Assuming 0 is the rotation facing north
	elif road_direction == Vector3(1, 0, 0):  # East
		return 16  # Adjust these values based on your rotation system
	elif road_direction == Vector3(0, 0, 1):  # South
		return 0
	elif road_direction == Vector3(-1, 0, 0):  # West
		return 22
	return 10 # Default rotation if no road is found

func _check_neighbors(cell: Vector3, unvisited: Array) -> Array[Vector3]:
	var list: Array[Vector3] = []
	for n: Vector3 in cell_walls.keys():
		var direction: Vector3 = cell + n
		if direction in unvisited:
			list.append(direction)
	return list

func _fill_gaps(current_position: Vector3, direction: Vector3) -> void:
	var tile_type: int
	for i: int in range(1, SPACING):
		if direction.x != 0:
			tile_type = 5
			current_position.x += 1 if direction.x > 0 else -1
		elif direction.z != 0:
			tile_type = 10
			current_position.z += 1 if direction.z > 0 else -1
		else:
			tile_type = 0
		if tile_type:
			building_locations.erase(Vector3(current_position.x, 0, current_position.z))
			_place_cell.rpc(current_position, _get_cell_item(tile_type), _get_cell_rotation(tile_type))
#endregion

#region Map polishes
func _erase_walls() -> void:
	for i: int in range(WIDTH * HEIGHT * erase_fraction):
		var x: int = randi_range(1, int(float(WIDTH) / SPACING) - SPACING) * SPACING
		var z: int = randi_range(1, int(float(HEIGHT) / SPACING) - SPACING) * SPACING
		var cell: Vector3 = Vector3(x, 0, z)
		var current_cell: int = _get_cell_item_from_position(cell)
		var neighbor: Vector3 = cell_walls.keys()[randi() % cell_walls.size()]
		
		if current_cell & cell_walls[neighbor]:
			var walls: int = current_cell - cell_walls[neighbor]
			var neighbor_walls: int = _get_cell_item_from_position(cell + neighbor) - cell_walls[-neighbor]
			
			_place_cell.rpc(cell, _get_cell_item(walls), _get_cell_rotation(walls))
			_place_cell.rpc(cell + neighbor, _get_cell_item(neighbor_walls), _get_cell_rotation(neighbor_walls))
			_fill_gaps(cell, neighbor)
			
#endregion

#region Cell Helpers
func _get_cell_item_from_position(cell_position: Vector3) -> int:
	var item: int = get_cell_item(cell_position)
	var orientation: int = get_cell_item_orientation(cell_position)
	match item:
		0:
			return 0
		1:
			match orientation:
				10:
					return 2
				16:
					return 4
				22:
					return 1
				_:
					return 8
		2:
			match orientation:
				10:
					return 6
				16:
					return 12
				22:
					return 3
				_:
					return 9
		3:
			match orientation:
				22:
					return 5
				_:
					return 10
		4:
			match orientation:
				10:
					return 14
				16:
					return 13
				22:
					return 7
				_:
					return 11
		_:
			return 15

func _get_cell_item(number: int) -> int:
	match number:
		0:
			return 0
		1, 2, 4, 8:
			return 1
		3, 6, 9, 12:
			return 2
		5, 10:
			return 3
		7, 11, 13, 14:
			return 4
		_:
			return 5

func _get_cell_rotation(number: int) -> int:
	match number:
		2, 6, 14:
			return 10 # 180 degrees
		4, 12, 13:
			return 16 # 270 degrees
		1, 3, 5, 7:
			return 22 # 90 degrees
		_:
			return 0 # Default
#endregion

@rpc("authority", "call_local")
func _place_cell(location: Vector3, cell: int, cell_rotation: int) -> void:
	set_cell_item(location, cell, cell_rotation)
