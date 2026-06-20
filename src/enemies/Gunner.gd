extends Enemy
class_name Gunner

const PROJECTILE_SCENE = preload("res://src/enemies/GunnerProjectile.tscn")

@export var detect_distance: float = 560.0
@export var shoot_interval: float = 1.15
@export var muzzle_offset: Vector2 = Vector2(28, -8)

var shoot_timer := 0.35

func _ready() -> void:
	super._ready()
	max_health = max(max_health, 2)
	health = max_health

func _enemy_ai(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if not player:
		return

	var to_player := player.global_position - global_position
	if abs(to_player.x) > 4.0:
		enemy_sprite.flip_h = to_player.x < 0.0

	shoot_timer = max(0.0, shoot_timer - delta)
	if to_player.length() <= detect_distance and shoot_timer <= 0.0:
		_shoot_at(player)
		shoot_timer = shoot_interval

func _shoot_at(player: Player) -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as GunnerProjectile
	get_parent().add_child(projectile)
	var facing := -1.0 if enemy_sprite.flip_h else 1.0
	projectile.global_position = global_position + Vector2(muzzle_offset.x * facing, muzzle_offset.y)
	projectile.setup(player.global_position - projectile.global_position)
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "scale", Vector2(0.58, 0.52), 0.08)
	tween.tween_property(enemy_sprite, "scale", Vector2(0.55, 0.55), 0.12)
