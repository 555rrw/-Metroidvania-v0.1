extends Camera2D
class_name PlayerCamera

@export var target: Node2D
@export var follow_speed: float = 8.0

var shake_intensity: float = 0.0
var shake_duration: float = 0.0

func _ready() -> void:
	make_current()
	if not target:
		var players = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			target = players[0]

func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

	if shake_duration > 0.0:
		shake_duration -= delta
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_duration <= 0.0:
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO

func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
