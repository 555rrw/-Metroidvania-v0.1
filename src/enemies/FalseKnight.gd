# -- Identity ---------------------------------------------------------------
extends Enemy
class_name FalseKnight

# -- Constants And Types ---------------------------------------------------------------
const ShockwaveScene = preload("res://src/objects/Shockwave.tscn")

# -- Exports ---------------------------------------------------------------
@export var speed: float = 82.0
@export var jump_cooldown: float = 3.4

# -- Constants And Types ---------------------------------------------------------------
enum BossState { WALK, WINDUP, LEAPING, RECOVER, STAGGER }

# -- Runtime State ---------------------------------------------------------------
var boss_state: BossState = BossState.WALK

var jump_timer: float = 0.0
var state_timer: float = 0.0
var stagger_hits: int = 0
var next_stagger_limit: int = 5
var boss_direction: int = -1
var phase: int = 1

var double_jump_scene = preload("res://src/objects/AbilityUnlock.tscn")
var sfx_slam = preload("res://assets/audio/false_knight/AttackSound_01.wav")
var sfx_damage = preload("res://assets/audio/false_knight/Damage_01.wav")

# -- Node References ---------------------------------------------------------------
@onready var sfx_player = $SFXPlayer

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	max_health = 18
	health = max_health
	knockback_resistance = 1.0
	death_burst_color = Color(0.85, 0.76, 0.55, 1.0)
	super._ready()

	enemy_sprite.hframes = 1
	enemy_sprite.vframes = 1
	enemy_sprite.frame = 0
	jump_timer = jump_cooldown

# -- Internal Helpers ---------------------------------------------------------------
func _enemy_ai(delta: float) -> void:
	_update_phase()

	if not is_on_floor():
		velocity.y += 1800.0 * delta
	else:
		velocity.y = 0.0

	var players = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		velocity.x = 0.0
		move_and_slide()
		return

	var player = players[0] as Player
	var to_player = player.global_position - global_position
	if jump_timer > 0.0:
		jump_timer -= delta

	match boss_state:
		BossState.WALK:
			boss_direction = int(sign(to_player.x))
			if boss_direction == 0:
				boss_direction = -1

			velocity.x = boss_direction * _phase_speed()
			enemy_sprite.flip_h = boss_direction == 1

			if jump_timer <= 0.0 and is_on_floor() and abs(to_player.x) < 520.0:
				boss_state = BossState.WINDUP
				state_timer = max(0.22, 0.42 - phase * 0.06)
				velocity.x = 0.0

		BossState.WINDUP:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				boss_direction = int(sign(to_player.x))
				if boss_direction == 0:
					boss_direction = -1
				velocity.x = boss_direction * (240.0 + phase * 55.0)
				velocity.y = -700.0
				boss_state = BossState.LEAPING

		BossState.LEAPING:
			if is_on_floor() and velocity.y >= 0.0:
				boss_state = BossState.RECOVER
				state_timer = max(0.28, 0.62 - phase * 0.08)
				velocity.x = 0.0
				jump_timer = _phase_jump_cooldown()
				_perform_land_slam()

		BossState.RECOVER:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				boss_state = BossState.WALK

		BossState.STAGGER:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				boss_state = BossState.WALK
				stagger_hits = 0
				next_stagger_limit = max(3, 6 - phase)

	move_and_slide()

func _perform_land_slam() -> void:
	_play_boss_sfx(sfx_slam)

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(18.0 + phase * 3.0, 0.35)

	_spawn_shockwave(-1)
	_spawn_shockwave(1)

	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		var player = players[0] as Player
		var dist = global_position.distance_to(player.global_position)
		if dist < 170.0 and player.is_on_floor() and not player.event:
			var dir = (player.global_position - global_position).normalized()
			if dir.x == 0.0:
				dir.x = -1.0
			player.take_damage(contact_damage, Vector2(sign(dir.x), -0.5))

func _spawn_shockwave(dir: int) -> void:
	if not get_parent():
		return

	var wave = ShockwaveScene.instantiate()
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(dir * 62.0, 62.0)
	wave.setup(dir, 330.0 + phase * 70.0)

# -- Public API ---------------------------------------------------------------
func take_damage(amount: int, attack_dir: Vector2, hit_info = null) -> void:
	_play_boss_sfx(sfx_damage)
	if boss_state == BossState.STAGGER:
		super.take_damage(amount * 2, attack_dir, hit_info)
	else:
		super.take_damage(amount, attack_dir, hit_info)
		stagger_hits += 1

	if is_dead:
		return

	_update_phase()
	if boss_state != BossState.STAGGER and stagger_hits >= next_stagger_limit:
		boss_state = BossState.STAGGER
		state_timer = max(1.6, 2.5 - phase * 0.25)
		velocity = Vector2.ZERO

# GPT5.5_LOCK: verified 2026-06-21. Room3 completion requires both boss_defeated and double_jump reward before Room4.
func die() -> void:
	is_dead = true

	var double_jump = double_jump_scene.instantiate() as AbilityUnlock
	double_jump.ability_name = "double_jump"
	double_jump.id = "false_knight_double_jump"
	double_jump.global_position = global_position + Vector2(0, -36)
	get_parent().call_deferred("add_child", double_jump)

	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		if not ("boss_defeated" in game.events):
			game.events.append("boss_defeated")
		game.save_game()

	super.die()

# -- Internal Helpers ---------------------------------------------------------------
func _update_phase() -> void:
	if health <= 5:
		phase = 3
	elif health <= 11:
		phase = 2
	else:
		phase = 1

func _phase_speed() -> float:
	return speed + float(phase - 1) * 34.0

func _phase_jump_cooldown() -> float:
	return max(1.25, jump_cooldown - float(phase - 1) * 0.72)

func _play_boss_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
