extends CharacterBody2D
class_name Enemy

@export var max_health: int = 2
@export var contact_damage: int = 1
@export var knockback_resistance: float = 0.0
@export var knockback_force: float = 260.0
@export var death_burst_color: Color = Color(0.65, 0.74, 0.86, 1.0)

var health: int = 2
var knockback_timer: float = 0.0
var flash_timer: float = 0.0
var is_dead: bool = false

@onready var enemy_sprite = $Sprite2D

func _ready() -> void:
	health = max_health
	add_to_group(&"enemies")

	# Connect local contact damage check
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		# HDR white flash modulation trick
		enemy_sprite.modulate = Color(5.0, 5.0, 5.0, 1.0)
		if flash_timer <= 0.0:
			enemy_sprite.modulate = Color(1, 1, 1, 1)

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
		move_and_slide()
	else:
		_enemy_ai(delta)

# Virtual method to be overridden by child classes
func _enemy_ai(_delta: float) -> void:
	pass

func take_damage(amount: int, attack_dir: Vector2, hit_info = null) -> void:
	if is_dead:
		return

	health = max(0, health - amount)
	flash_timer = 0.12
	if hit_info and hit_info.soul_gain > 0 and hit_info.source and hit_info.source.has_method("gain_soul"):
		hit_info.source.gain_soul(hit_info.soul_gain)

	# Apply knockback
	if knockback_resistance < 1.0:
		knockback_timer = 0.18
		velocity = attack_dir * (knockback_force * (1.0 - knockback_resistance))
		# Add a slight vertical upward lift to make hit feel satisfying
		velocity.y = min(velocity.y, -120.0)

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	_spawn_death_burst()
	# Fade out and free
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)

func _spawn_death_burst() -> void:
	if not get_parent():
		return

	var burst := Node2D.new()
	get_parent().add_child(burst)
	burst.global_position = global_position

	for i in range(8):
		var shard := ColorRect.new()
		shard.size = Vector2(7, 7)
		shard.position = -shard.size * 0.5
		shard.color = death_burst_color
		burst.add_child(shard)

		var angle := TAU * float(i) / 8.0
		var target := Vector2(cos(angle), sin(angle)) * randf_range(22.0, 48.0)
		var tween := shard.create_tween().set_parallel(true)
		tween.tween_property(shard, "position", target, 0.32)
		tween.tween_property(shard, "modulate:a", 0.0, 0.32)

	var cleanup := get_tree().create_timer(0.45)
	cleanup.timeout.connect(burst.queue_free)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		var dir = (body.global_position - global_position).normalized()
		# If direction is pure vertical or near zero, use facing direction
		if abs(dir.x) < 0.1:
			dir.x = 1.0 if body.global_position.x > global_position.x else -1.0
		body.take_damage(contact_damage, dir)
