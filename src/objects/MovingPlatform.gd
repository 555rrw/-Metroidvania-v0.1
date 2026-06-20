extends AnimatableBody2D
class_name MovingPlatform

@export var speed: float = 120.0
@export var wait_time: float = 1.0

var waypoints: Array[Vector2] = []
var current_index: int = 0
var target_pos: Vector2
var timer: float = 0.0
var state: int = 0 # 0: Moving, 1: Waiting

func _ready() -> void:
	# Start from initial position
	waypoints.append(global_position)
	# Grab any Marker2D children as waypoints
	for child in get_children():
		if child is Marker2D:
			waypoints.append(child.global_position)

	if waypoints.size() > 1:
		current_index = 1
		target_pos = waypoints[1]
	else:
		state = 1

func _physics_process(delta: float) -> void:
	if waypoints.size() <= 1:
		return

	if state == 0:
		global_position = global_position.move_toward(target_pos, speed * delta)
		if global_position.distance_to(target_pos) < 1.0:
			global_position = target_pos
			state = 1
			timer = wait_time
	elif state == 1:
		timer -= delta
		if timer <= 0.0:
			current_index = (current_index + 1) % waypoints.size()
			target_pos = waypoints[current_index]
			state = 0
