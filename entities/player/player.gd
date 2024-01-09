extends VehicleBody3D

@export_group("Steering")
@export var steer_speed: float = 1.5
@export var steer_limit: float = 0.6

@export_group("Engine")
@export var engine_force_value: float = 40
@export var max_speed: float = 200

@export_group("Brake")
@export var brake_force: float = 3

@onready var wheel_back_left: VehicleWheel3D = $WheelBackLeft
@onready var wheel_back_right: VehicleWheel3D = $WheelBackRight
@onready var speed_label: Label = $HUD/SpeedLabel
@onready var camera: Camera3D = $Camera3D

var steer_target: float = 0
var current_speed: float = 0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if not _is_local_player():
		camera.queue_free()
		speed_label.queue_free()

func _is_local_player() -> bool:
	return name == str(Network.local_player_id)

func _process(delta: float) -> void:
	if _is_local_player():
		_calculate_speed(delta)
		_drive(delta)

func _calculate_speed(delta: float) -> void:
	current_speed = linear_velocity.length() * Engine.get_frames_per_second() * delta
	speed_label.text = str(floor(current_speed)) + " KM/h"
	apply_central_force(Vector3.DOWN * current_speed)

func _drive(delta: float) -> void:
	_apply_steering(delta)
	_apply_engine_force()
	_apply_brakes()

func _apply_steering(delta: float) -> void:
	steer_target = Input.get_axis("ui_right", "ui_left")
	steer_target *= steer_limit
	steering = move_toward(steering, steer_target, steer_speed * delta)

func _apply_engine_force() -> void:
	var fwd_mps: float = transform.basis.x.x
	if Input.is_action_pressed("ui_down"):
	# Increase engine force at low speeds to make the initial acceleration faster.
		if current_speed < 20 and current_speed != 0:
			engine_force = clamp(engine_force_value * 3 / current_speed, 0, 300)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
	if Input.is_action_pressed("ui_up"):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if fwd_mps >= -1:
			if current_speed < 30 and current_speed != 0:
				engine_force = -clamp(engine_force_value * 10 / current_speed, 0, 300)
			else:
				engine_force = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0

func _apply_brakes() -> void:
	if Input.is_action_pressed("ui_select"):
		brake = brake_force
		wheel_back_left.wheel_friction_slip = 0.8
		wheel_back_right.wheel_friction_slip = 0.8
	else:
		wheel_back_left.wheel_friction_slip = 3
		wheel_back_right.wheel_friction_slip = 3

