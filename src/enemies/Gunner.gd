extends Enemy
class_name Gunner

const PROJECTILE_SCENE = preload("res://src/enemies/GunnerProjectile.tscn")

@export var detect_distance: float = 560.0
@export var shoot_interval: float = 1.6
@export var muzzle_offset: Vector2 = Vector2(28, -8)

var shoot_timer := 0.5
var is_winding_up := false

func _ready() -> void:
	super._ready()
	max_health = max(max_health, 2)
	health = max_health

func _enemy_ai(delta: float) -> void:
	# Apply gravity
	velocity.y += 1500.0 * delta

	var player := get_tree().get_first_node_in_group(&"player") as Player
	if not player:
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if abs(to_player.x) > 4.0 and not is_winding_up:
		enemy_sprite.flip_h = to_player.x < 0.0

	shoot_timer = max(0.0, shoot_timer - delta)
	
	if to_player.length() <= detect_distance and shoot_timer <= 0.0 and not is_winding_up:
		_windup_and_shoot(player)

	# Slight friction
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()

func _windup_and_shoot(player: Player) -> void:
	is_winding_up = true
	var tween = create_tween()
	# Anticipation squash
	tween.tween_property(enemy_sprite, "scale", Vector2(0.65, 0.45), 0.3)
	tween.tween_callback(func():
		_shoot_at(player)
		# Recoil physics
		var facing = -1.0 if enemy_sprite.flip_h else 1.0
		velocity.x = -facing * 120.0
		is_winding_up = false
		shoot_timer = shoot_interval
	)
	# Recover scale
	tween.tween_property(enemy_sprite, "scale", Vector2(0.55, 0.55), 0.2)

func _shoot_at(player: Player) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as GunnerProjectile
	get_parent().add_child(projectile)
	var facing := -1.0 if enemy_sprite.flip_h else 1.0
	projectile.global_position = global_position + Vector2(muzzle_offset.x * facing, muzzle_offset.y)
	projectile.setup(player.global_position - projectile.global_position)
