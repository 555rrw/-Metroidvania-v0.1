extends Area2D
class_name FallingTrap

@export var damage: int = 1
@export var fall_distance: float = 520.0
@export var fall_time: float = 0.75
@export var fade_delay: float = 0.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func trigger() -> void:
	if triggered:
		return
	triggered = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y + fall_distance, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "rotation", 0.4, fall_time)
	await tween.finished
	await get_tree().create_timer(fade_delay).timeout
	collision_shape.set_deferred("disabled", true)
	var fade := create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, 0.25)
	fade.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var dir := (body.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
		body.take_damage(damage, dir)
