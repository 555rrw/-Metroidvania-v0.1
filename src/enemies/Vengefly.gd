# -- Identity ---------------------------------------------------------------
## 飛蟲敵人 AI：偵測後追逐/盤旋俯衝
extends Enemy
class_name Vengefly

# -- Exports ---------------------------------------------------------------
@export var speed: float = 130.0
@export var detect_radius: float = 260.0

# -- Constants And Types ---------------------------------------------------------------
enum FlyState { HOVER, CHASE }

# -- Runtime State ---------------------------------------------------------------
var current_fly_state: FlyState = FlyState.HOVER

var start_pos: Vector2
var hover_timer: float = 0.0
var frame_timer: float = 0.0

# -- Exports ---------------------------------------------------------------
@export var anim_fps: float = 10.0

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	super._ready()
	start_pos = global_position
	enemy_sprite.hframes = 1
	enemy_sprite.vframes = 1
	enemy_sprite.frame = 0

# -- Internal Helpers ---------------------------------------------------------------
func _enemy_ai(delta: float) -> void:
	var players = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		_hover(delta)
		return

	var player = players[0] as Player
	var dist = global_position.distance_to(player.global_position)

	match current_fly_state:
		FlyState.HOVER:
			_hover(delta)
			if dist < detect_radius and not player.event:
				current_fly_state = FlyState.CHASE
		FlyState.CHASE:
			# Fly directly toward player
			var dir = global_position.direction_to(player.global_position)
			velocity = dir * speed

			# Flip sprite
			enemy_sprite.flip_h = (velocity.x > 0)

			# If player is too far or dead, lose aggro
			if dist > detect_radius * 1.5 or player.health <= 0:
				current_fly_state = FlyState.HOVER
				start_pos = global_position

	# Animate frame
	if enemy_sprite.hframes > 1:
		frame_timer += delta
		if frame_timer >= (1.0 / anim_fps):
			frame_timer = 0.0
			enemy_sprite.frame = (enemy_sprite.frame + 1) % enemy_sprite.hframes

	move_and_slide()

func _hover(delta: float) -> void:
	hover_timer += delta
	# Gently hover up and down around start_pos

	var target_y = start_pos.y + sin(hover_timer * 4.0) * 15.0
	global_position.y = move_toward(global_position.y, target_y, 40.0 * delta)
	velocity.x = move_toward(velocity.x, 0.0, 100.0 * delta)
	velocity.y = 0.0
