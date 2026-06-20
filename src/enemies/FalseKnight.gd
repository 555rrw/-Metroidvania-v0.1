extends Enemy
class_name FalseKnight

@export var speed: float = 80.0
@export var jump_cooldown: float = 3.5

enum BossState { WALK, JUMP_START, LEAPING, SLAM, STAGGER }
var boss_state: BossState = BossState.WALK

var jump_timer: float = 0.0
var state_timer: float = 0.0
var stagger_hits: int = 0
var next_stagger_limit: int = 5
var boss_direction: int = -1

# Reference to the double jump collectible to spawn on death
var double_jump_scene = preload("res://src/objects/AbilityUnlock.tscn")
var sfx_slam = preload("res://assets/audio/false_knight/AttackSound_01.wav")
var sfx_damage = preload("res://assets/audio/false_knight/Damage_01.wav")

@onready var sfx_player = $SFXPlayer

func _ready() -> void:
	max_health = 16
	health = max_health
	knockback_resistance = 1.0 # Heavy boss, no knockback
	super._ready()

	enemy_sprite.hframes = 1
	enemy_sprite.vframes = 1
	enemy_sprite.frame = 0
	jump_timer = jump_cooldown

func _enemy_ai(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += 1800.0 * delta
	else:
		velocity.y = 0.0

	var players = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		velocity.x = 0
		move_and_slide()
		return

	var player = players[0] as Player
	var to_player = player.global_position - global_position

	if jump_timer > 0.0:
		jump_timer -= delta

	match boss_state:
		BossState.WALK:
			boss_direction = sign(to_player.x)
			if boss_direction == 0: boss_direction = -1

			velocity.x = boss_direction * speed
			enemy_sprite.flip_h = (boss_direction == 1)

			enemy_sprite.frame = 0

			if jump_timer <= 0.0 and is_on_floor() and abs(to_player.x) < 400.0:
				boss_state = BossState.JUMP_START
				state_timer = 0.4
				velocity.x = 0

		BossState.JUMP_START:
			# Anticipation pose
			enemy_sprite.frame = 0
			state_timer -= delta
			if state_timer <= 0.0:
				# Leap towards player
				boss_direction = sign(to_player.x)
				if boss_direction == 0: boss_direction = -1
				velocity.x = boss_direction * 250.0
				velocity.y = -700.0
				boss_state = BossState.LEAPING

		BossState.LEAPING:
			enemy_sprite.frame = 0
			if is_on_floor() and velocity.y >= 0:
				# Land and slam
				boss_state = BossState.SLAM
				state_timer = 0.5
				velocity.x = 0
				jump_timer = jump_cooldown
				_perform_land_slam()

		BossState.SLAM:
			# Slam visual recovery
			enemy_sprite.frame = 0
			state_timer -= delta
			if state_timer <= 0.0:
				boss_state = BossState.WALK

		BossState.STAGGER:
			# Staggered state (vulnerable, sitting down)
			enemy_sprite.frame = 0
			velocity.x = 0
			state_timer -= delta
			if state_timer <= 0.0:
				# Recover
				boss_state = BossState.WALK
				stagger_hits = 0
				next_stagger_limit = 5

	move_and_slide()

func _perform_land_slam() -> void:
	_play_boss_sfx(sfx_slam)
	# Shake camera
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(18.0, 0.45)

	# Deal damage to player if they are close on floor
	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		var player = players[0] as Player
		var dist = global_position.distance_to(player.global_position)
		if dist < 160.0 and player.is_on_floor() and not player.event:
			var dir = (player.global_position - global_position).normalized()
			if dir.x == 0: dir.x = -1.0
			player.take_damage(contact_damage, Vector2(sign(dir.x), -0.5))

func take_damage(amount: int, attack_dir: Vector2) -> void:
	_play_boss_sfx(sfx_damage)
	if boss_state == BossState.STAGGER:
		# Double damage during stagger!
		super.take_damage(amount * 2, attack_dir)
	else:
		super.take_damage(amount, attack_dir)
		stagger_hits += 1
		if stagger_hits >= next_stagger_limit:
			# Enter stagger!
			boss_state = BossState.STAGGER
			state_timer = 2.5 # Vulnerable for 2.5s
			velocity.x = 0
			velocity.y = 0

func die() -> void:
	is_dead = true
	# Spawn Double Jump Upgrade
	var double_jump = double_jump_scene.instantiate() as AbilityUnlock
	double_jump.ability_name = "double_jump"
	double_jump.global_position = global_position + Vector2(0, -20)
	get_parent().call_deferred("add_child", double_jump)

	# Mark boss defeated event in Game
	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		game.events.append("boss_defeated")
		game.save_game()

	super.die()

func _play_boss_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
