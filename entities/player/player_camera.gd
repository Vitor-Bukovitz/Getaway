extends Camera3D

@export var target_distance: float = 5
@export var target_height: float = 2
@export var speed: float = 20.0
@export var follow_this: Node3D

@onready var last_lookat: Vector3 = follow_this.global_transform.origin

func _physics_process(delta: float) -> void:
	var delta_v: Vector3 = global_transform.origin - follow_this.global_transform.origin
	var target_pos: Vector3 = global_transform.origin
	
	# ignore y
	delta_v.y = 0.0
	
	if delta_v.length() > target_distance:
		delta_v = delta_v.normalized() * target_distance
		delta_v.y = target_height
		target_pos = follow_this.global_transform.origin + delta_v
	else:
		target_pos.y = follow_this.global_transform.origin.y + target_height
	
	global_transform.origin = global_transform.origin.lerp(target_pos, delta * speed)
	last_lookat = last_lookat.lerp(follow_this.global_transform.origin, delta * speed)
	
	look_at(last_lookat, Vector3.UP)
