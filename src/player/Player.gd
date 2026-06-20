extends CharacterBody2D
class_name Player

# Signal emitted when player health changes
signal health_changed(current_health: int)
signal player_died()

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var left_wall_ray = $LeftWallRay
@onready var right_wall_ray = $RightWallRay
@onready var nail_area = $NailArea
@onready var nail_collision = $NailArea/CollisionShape2D
@onready var nail_sprite = $NailArea/Sprite2D
@onready var sfx_player = $SFXPlayer

# --- Physics Constants (scaled and tuned for 1280x720) ---
@export_group("Movement")
@export var walk_speed: float = 350.0
@export var air_speed: float = 350.0

@export_group("Jump")
@export var jump_velocity: float = -620.0
@export var double_jump_velocity: float = -580.0
@export var gravity: float = 1900.0
@export var fall_gravity: float = 2300.0
@export var vy_multiplier: float = 0.4 # Variable jump height multiplier
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1

@export_group("Wall Slide & Wall Jump")
@export var wall_slide_velocity: float = 140.0
@export var wall_jump_speed_x: float = 400.0
@export var wall_jump_speed_y: float = -550.0
@export var wall_jump_time: float = 0.15

@export_group("Dash")
@export var dash_speed: float = 850.0
@export var dash_time: float = 0.22
@export var dash_cooldown: float = 0.4

@export_group("Combat")
@export var max_health: int = 5
@export var attack_cooldown_time: float = 0.32
@export var attack_duration_time: float = 0.15
@export var pogo_bounce_velocity: float = -580.0
@export var knockback_force: float = 300.0

# --- State Variables ---
enum State { IDLE, RUN, JUMP, FALL, DASH, WALL_SLIDE, WALL_JUMP, HURT }
var current_state: State = State.IDLE

var health: int = 5
var abilities: Array[StringName] = [] # e.g. ["dash", "double_jump"]

var current_jumps: int = 0
var max_jumps: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var wall_jump_timer: float = 0.0
var wall_direction: int = 0

var attack_cooldown_timer: float = 0.0
var attack_duration_timer: float = 0.0
var attack_direction: Vector2 = Vector2.ZERO

var hurt_timer: float = 0.0
var invincible_timer: float = 0.0
var hurt_knockback_dir: float = 0.0

var facing_direction: int = 1
var event: bool = false # Used by MetSys for room loading/transitions
var reset_position: Vector2 = Vector2.ZERO

# --- Dynamic Animation Manager ---
var animations: Dictionary = {}
var current_animation_name: String = ""
var anim_frame_index: int = 0
var anim_timer: float = 0.0
var anim_fps: float = 10.0

# Audio files Preloaded
var sfx_jump = preload("res://assets/audio/PlayerJump.wav")
var sfx_damage = preload("res://assets/audio/PlayerDamage.wav")
var sfx_hit = preload("res://assets/audio/PlayerBash.wav")

func _ready() -> void:
	add_to_group(&"player")
	health = max_health
	reset_position = position

	# Load animations dynamically
	_load_all_animations()
	play_anim("idle", 8.0)

	# Set nail collision disabled initially
	nail_collision.disabled = true
	nail_sprite.visible = false

	# Connect attack hit detection
	nail_area.body_entered.connect(_on_nail_area_body_entered)

func _load_all_animations() -> void:
	animations["idle"] = _load_animation_frames("idle")
	animations["walk"] = _load_animation_frames("walk")
	animations["jump"] = _load_animation_frames("jump")
	animations["dash"] = _load_animation_frames("dash")
	animations["wall_slide"] = _load_animation_frames("wall_slide")
	animations["hurt"] = _load_animation_frames("hurt")
	animations["attack"] = _load_animation_frames("attack")

func _load_animation_frames(dir_name: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var i = 1
	while true:
		var path = "res://assets/sprites/player/%s/%d.PNG" % [dir_name, i]
		if ResourceLoader.exists(path):
			frames.append(load(path) as Texture2D)
			i += 1
		else:
			break
	if frames.is_empty():
		# Try lowercase extension just in case
		i = 1
		while true:
			var path = "res://assets/sprites/player/%s/%d.png" % [dir_name, i]
			if ResourceLoader.exists(path):
				frames.append(load(path) as Texture2D)
				i += 1
			else:
				break
	return frames

# Play animation helper
func play_anim(anim_name: String, fps: float = 10.0) -> void:
	if current_animation_name == anim_name and anim_fps == fps:
		return
	current_animation_name = anim_name
	anim_fps = fps
	anim_frame_index = 0
	anim_timer = 0.0
	if animations.has(anim_name) and not animations[anim_name].is_empty():
		sprite.texture = animations[anim_name][0]

func _process(delta: float) -> void:
	# Handle animation frame updates
	if animations.has(current_animation_name) and not animations[current_animation_name].is_empty():
		var frames = animations[current_animation_name]
		anim_timer += delta
		if anim_timer >= (1.0 / anim_fps):
			anim_timer = 0.0
			anim_frame_index = (anim_frame_index + 1) % frames.size()
			sprite.texture = frames[anim_frame_index]

	# Update nail attack visual direction & progress
	if attack_duration_timer > 0.0:
		attack_duration_timer -= delta
		if attack_duration_timer <= 0.0:
			nail_collision.disabled = true
			nail_sprite.visible = false

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if invincible_timer > 0.0:
		invincible_timer -= delta
		# Visual flash effect
		sprite.modulate.a = 0.5 if Engine.get_frames_drawn() % 8 < 4 else 1.0
	else:
		sprite.modulate.a = 1.0

func _physics_process(delta: float) -> void:
	# In event state (e.g. transitioning rooms via MetSys), do nothing
	if event:
		velocity = Vector2.ZERO
		move_and_slide()
		play_anim("idle")
		return

	# Handle input buffers and timers
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if is_on_floor():
		coyote_timer = coyote_time
		current_jumps = 0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Check wall collisions
	var is_against_left_wall = left_wall_ray.is_colliding()
	var is_against_right_wall = right_wall_ray.is_colliding()
	var wall_sum = (1 if is_against_right_wall else 0) - (1 if is_against_left_wall else 0)

	# --- State Machine Update ---
	match current_state:
		State.IDLE:
			play_anim("idle", 8.0)
			current_jumps = 0

			# Apply gravity
			velocity.y += fall_gravity * delta
			velocity.x = move_toward(velocity.x, 0, walk_speed * 10 * delta)

			var move_input = Input.get_axis("left", "right")
			if move_input != 0:
				facing_direction = sign(move_input)
				current_state = State.RUN
			elif jump_buffer_timer > 0.0:
				_perform_jump()
			elif not is_on_floor():
				current_state = State.FALL
			elif Input.is_action_just_pressed("dash") and _can_dash():
				_perform_dash(move_input)

		State.RUN:
			play_anim("walk", 12.0)
			current_jumps = 0

			# Apply gravity
			velocity.y += fall_gravity * delta

			var move_input = Input.get_axis("left", "right")
			if move_input == 0:
				current_state = State.IDLE
			else:
				facing_direction = sign(move_input)
				velocity.x = move_input * walk_speed

			if jump_buffer_timer > 0.0:
				_perform_jump()
			elif not is_on_floor():
				current_state = State.FALL
			elif Input.is_action_just_pressed("dash") and _can_dash():
				_perform_dash(move_input)

		State.JUMP:
			play_anim("jump", 10.0)
			# Gravity based on upward/downward movement
			var current_gravity = gravity if velocity.y < 0 else fall_gravity
			velocity.y += current_gravity * delta

			var move_input = Input.get_axis("left", "right")
			if move_input != 0:
				facing_direction = sign(move_input)
				velocity.x = move_input * air_speed
			else:
				velocity.x = move_toward(velocity.x, 0, air_speed * 4 * delta)

			# Variable Jump Height (releasing jump early cuts vertical speed)
			if Input.is_action_just_released("jump") and velocity.y < 0:
				velocity.y *= vy_multiplier

			# Double Jump check
			if Input.is_action_just_pressed("jump") and _can_double_jump():
				_perform_double_jump()

			if velocity.y >= 0:
				current_state = State.FALL
			elif is_on_floor():
				current_state = State.IDLE
			elif Input.is_action_just_pressed("dash") and _can_dash():
				_perform_dash(move_input)
			elif wall_sum != 0 and move_input == wall_sum:
				current_state = State.WALL_SLIDE
				wall_direction = wall_sum

		State.FALL:
			play_anim("jump", 10.0) # Using jump anim frames for fall as is typical
			velocity.y += fall_gravity * delta

			var move_input = Input.get_axis("left", "right")
			if move_input != 0:
				facing_direction = sign(move_input)
				velocity.x = move_input * air_speed
			else:
				velocity.x = move_toward(velocity.x, 0, air_speed * 4 * delta)

			# Coyote Time jump
			if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
				_perform_jump()
			# Double Jump check
			elif Input.is_action_just_pressed("jump") and _can_double_jump():
				_perform_double_jump()
			elif is_on_floor():
				current_state = State.IDLE
			elif Input.is_action_just_pressed("dash") and _can_dash():
				_perform_dash(move_input)
			elif wall_sum != 0 and move_input == wall_sum:
				current_state = State.WALL_SLIDE
				wall_direction = wall_sum

		State.DASH:
			play_anim("dash", 12.0)
			dash_timer -= delta
			velocity.y = 0.0 # No gravity during dash

			# Move in facing direction
			velocity.x = facing_direction * dash_speed

			if dash_timer <= 0.0:
				if is_on_floor():
					current_state = State.IDLE
				else:
					current_state = State.FALL

			if Input.is_action_just_pressed("jump") and is_on_floor():
				dash_timer = 0.0
				_perform_jump()

		State.WALL_SLIDE:
			play_anim("wall_slide", 10.0)
			# Slowly slide down
			velocity.y = wall_slide_velocity
			velocity.x = 0

			var move_input = Input.get_axis("left", "right")
			# Detach if moving away from wall or not holding into wall
			if wall_sum == 0 or move_input == -wall_direction or move_input == 0:
				current_state = State.FALL
			elif jump_buffer_timer > 0.0:
				_perform_wall_jump()
			elif is_on_floor():
				current_state = State.IDLE
			elif Input.is_action_just_pressed("dash") and _can_dash():
				_perform_dash(move_input)

		State.WALL_JUMP:
			play_anim("jump", 10.0)
			wall_jump_timer -= delta

			# Move away from wall
			velocity.x = -wall_direction * wall_jump_speed_x
			velocity.y = wall_jump_speed_y

			if wall_jump_timer <= 0.0:
				current_state = State.FALL
			elif is_on_floor():
				current_state = State.IDLE
			elif Input.is_action_just_released("jump") and velocity.y < 0:
				velocity.y *= vy_multiplier
				current_state = State.FALL

		State.HURT:
			play_anim("hurt", 10.0)
			hurt_timer -= delta
			# Knockback velocity
			velocity.x = hurt_knockback_dir * knockback_force
			velocity.y += gravity * delta

			if hurt_timer <= 0.0:
				if is_on_floor():
					current_state = State.IDLE
				else:
					current_state = State.FALL

	# Apply scale to sprite based on facing direction
	sprite.flip_h = (facing_direction == -1)

	# --- Combat / Attack Input Check ---
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0 and current_state != State.HURT:
		_perform_attack()

	# Perform actual movement
	move_and_slide()

# --- Helper Methods for State Changes ---

func _perform_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	velocity.y = jump_velocity
	current_state = State.JUMP
	current_jumps = 1
	_play_sfx(sfx_jump)

func _perform_double_jump() -> void:
	jump_buffer_timer = 0.0
	velocity.y = double_jump_velocity
	current_state = State.JUMP
	current_jumps = 2
	_play_sfx(sfx_jump)

func _perform_wall_jump() -> void:
	jump_buffer_timer = 0.0
	wall_jump_timer = wall_jump_time
	facing_direction = -wall_direction
	velocity.x = -wall_direction * wall_jump_speed_x
	velocity.y = wall_jump_speed_y
	current_state = State.WALL_JUMP
	current_jumps = 1
	_play_sfx(sfx_jump)

func _perform_dash(move_input: float) -> void:
	if move_input != 0:
		facing_direction = sign(move_input)
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown
	current_state = State.DASH
	_play_sfx(sfx_jump) # Dash uses quick jump sound or whoosh

func _can_dash() -> bool:
	return ("dash" in abilities) and dash_cooldown_timer <= 0.0 and current_state != State.WALL_SLIDE

func _can_double_jump() -> bool:
	return ("double_jump" in abilities) and current_jumps < 2

# --- Combat Functions ---

func _perform_attack() -> void:
	attack_cooldown_timer = attack_cooldown_time
	attack_duration_timer = attack_duration_time

	# Determine attack direction based on inputs
	var up_input = Input.is_action_pressed("up")
	var down_input = Input.is_action_pressed("down")

	# Attack direction vector
	if up_input:
		attack_direction = Vector2.UP
	elif down_input and not is_on_floor():
		attack_direction = Vector2.DOWN
	else:
		attack_direction = Vector2(facing_direction, 0)

	# Configure Nail Hitbox
	nail_area.position = attack_direction * 48.0
	nail_collision.disabled = false

	# Configure Visual Nail Slash Effect
	nail_sprite.visible = true
	nail_sprite.rotation = attack_direction.angle()

	# Reset frame for attack animation
	play_anim("attack", 15.0)
	_play_sfx(sfx_hit)

	# Perform swing sweep: simple scale tween or timer-based frame logic
	var tween = create_tween()
	nail_sprite.scale = Vector2(0.2, 0.2)
	tween.tween_property(nail_sprite, "scale", Vector2(1.2, 1.2), attack_duration_time * 0.5)
	tween.tween_property(nail_sprite, "scale", Vector2(0.5, 0.5), attack_duration_time * 0.5)

# Triggered when nail hitbox overlaps something
func _on_nail_area_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body.has_method("take_damage"):
		body.take_damage(1, attack_direction)
		_play_sfx(sfx_hit)

		# Nail Bounce (Pogo) or Horizontal Recoil
		if attack_direction == Vector2.DOWN:
			velocity.y = pogo_bounce_velocity
			current_jumps = 0 # Reset double jump
			current_state = State.JUMP
		elif attack_direction == Vector2.UP:
			velocity.y = 150.0 # Small downward kick
		else:
			# Push player back horizontally
			velocity.x = -facing_direction * 220.0

# --- Health & Damage Functions ---

func take_damage(amount: int, dir: Vector2) -> void:
	if invincible_timer > 0.0 or current_state == State.HURT or event:
		return

	health = max(0, health - amount)
	health_changed.emit(health)
	_play_sfx(sfx_damage)

	# Camera Shake
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(12.0, 0.25)

	if health <= 0:
		# Player dies
		current_state = State.HURT
		velocity = Vector2.ZERO
		player_died.emit()
		kill.call_deferred()
	else:
		# Enter hurt recoil state
		current_state = State.HURT
		hurt_timer = 0.25
		invincible_timer = 1.3
		hurt_knockback_dir = -1.0 if dir.x > 0 else 1.0
		velocity = Vector2(hurt_knockback_dir * knockback_force, -250.0)

func kill() -> void:
	# Teleport player to reset position and load last room
	position = reset_position
	health = max_health
	health_changed.emit(health)
	current_state = State.IDLE
	velocity = Vector2.ZERO

	var game_node = get_tree().get_first_node_in_group(&"game")
	if game_node:
		game_node.load_room(MetSys.get_current_room_id())

func on_enter() -> void:
	reset_position = position

# --- Helper Utilities ---

func _play_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
