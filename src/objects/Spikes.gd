extends Area2D
class_name Spikes

@export var damage: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Damage the player, sending them back to their safety point
		body.take_damage(damage, Vector2.UP)
