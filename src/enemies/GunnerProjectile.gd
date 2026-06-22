# -- Identity ---------------------------------------------------------------
extends CharacterBody2D
class_name GunnerProjectile

# -- Exports ---------------------------------------------------------------
@export var speed: float = 310.0
@export var damage: int = 1
@export var lifetime: float = 3.0

# -- Node References ---------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D

# -- Runtime State ---------------------------------------------------------------
var direction := Vector2.RIGHT

# -- Public API ---------------------------------------------------------------
func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()

# -- Lifecycle ---------------------------------------------------------------
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	velocity = direction * speed

	var collision := move_and_collide(velocity * delta)
	if collision:
		var body := collision.get_collider()
		if body is Player:
			body.take_damage(damage, direction)
		queue_free()

# -- Public API ---------------------------------------------------------------
func take_damage(_amount: int, _attack_dir: Vector2, _hit_info = null) -> void:
	queue_free()
