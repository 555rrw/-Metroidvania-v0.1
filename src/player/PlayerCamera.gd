# -- Identity ---------------------------------------------------------------
## 玩家攝影機：跟隨/震動/上下看
extends Camera2D
class_name PlayerCamera

# -- Exports ---------------------------------------------------------------
@export var target: Node2D
@export var follow_speed: float = 8.0
@export var look_distance: float = 92.0
@export var look_speed: float = 5.5

# -- Runtime State ---------------------------------------------------------------
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var look_offset: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	make_current()
	if not target:

		var players = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			target = players[0]

func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
		_update_look_offset(delta)

	if shake_duration > 0.0:
		shake_duration -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_duration <= 0.0:
			shake_offset = Vector2.ZERO
	else:
		shake_offset = Vector2.ZERO

	offset = look_offset + shake_offset

# -- Public API ---------------------------------------------------------------
func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

# -- Internal Helpers ---------------------------------------------------------------
func _update_look_offset(delta: float) -> void:
	var desired := Vector2.ZERO
	if Input.is_action_pressed("up"):
		desired.y = -look_distance
	elif Input.is_action_pressed("down"):
		desired.y = look_distance
	look_offset = look_offset.lerp(desired, look_speed * delta)
