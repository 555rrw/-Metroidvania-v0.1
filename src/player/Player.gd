extends CharacterBody2D
class_name Player

signal health_changed(current_health: int)
signal soul_changed(current_soul: int, max_soul: int)
signal player_died()

const HitInfo = preload("res://src/combat/HitInfo.gd")
const VENGEFUL_SPIRIT_SCENE = preload("res://src/player/VengefulSpirit.tscn")

const ABILITY_DASH := StringName("dash")
const ABILITY_DOUBLE_JUMP := StringName("double_jump")
const ABILITY_VENGEFUL_SPIRIT := StringName("vengeful_spirit")

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var left_wall_ray = $LeftWallRay
@onready var right_wall_ray = $RightWallRay
@onready var nail_area = $NailArea
@onready var nail_collision = $NailArea/CollisionShape2D
@onready var nail_sprite = $NailArea/Sprite2D
@onready var sfx_player = $SFXPlayer

@export_group("Movement")
@export var walk_speed: float = 360.0
@export var air_speed: float = 350.0
@export var ground_acceleration: float = 3200.0
@export var ground_deceleration: float = 3600.0
@export var air_acceleration: float = 2300.0
@export var air_deceleration: float = 1300.0
@export var max_fall_speed: float = 860.0

@export_group("Jump")
@export var jump_velocity: float = -620.0
@export var double_jump_velocity: float = -580.0
@export var gravity: float = 1900.0
@export var fall_gravity: float = 2300.0
@export var vy_multiplier: float = 0.4
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1

@export_group("Wall")
@export var wall_slide_velocity: float = 140.0
@export var wall_jump_speed_x: float = 430.0
@export var wall_jump_speed_y: float = -560.0
@export var wall_jump_time: float = 0.14

@export_group("Dash")
@export var dash_speed: float = 880.0
@export var dash_time: float = 0.18
@export var dash_cooldown: float = 0.32
@export var dash_exit_speed_multiplier: float = 0.62

@export_group("Combat")
@export var max_health: int = 5
@export var attack_cooldown_time: float = 0.28
@export var attack_duration_time: float = 0.13
@export var pogo_bounce_velocity: float = -620.0
@export var side_recoil_force: float = 230.0
@export var up_recoil_force: float = 160.0
@export var knockback_force: float = 330.0
@export var hit_pause_time: float = 0.045

@export_group("Soul")
@export var max_soul: int = 99
@export var soul_per_nail_hit: int = 11
@export var focus_cost: int = 33
@export var focus_time: float = 0.9
@export var spell_cost: int = 33
@export var spell_damage: int = 2
@export var spell_cooldown_time: float = 0.35

enum State { IDLE, RUN, JUMP, FALL, DASH, WALL_SLIDE, WALL_JUMP, HURT, FOCUS }

var current_state: State = State.IDLE
var health: int = 5
var soul: int = 0
var abilities: Array[StringName] = []

var current_jumps: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var wall_jump_timer: float = 0.0
var wall_direction: int = 0

var attack_cooldown_timer: float = 0.0
var attack_duration_timer: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var attack_hit_bodies: Array[Node] = []

var hurt_timer: float = 0.0
var invincible_timer: float = 0.0
var hurt_knockback_dir: float = 0.0
var focus_timer: float = 0.0
var spell_cooldown_timer: float = 0.0
var hit_pause_timer: float = 0.0

var facing_direction: int = 1
var event: bool = false
var reset_position: Vector2 = Vector2.ZERO

var animations: Dictionary = {}
var current_animation_name: String = ""
var anim_frame_index: int = 0
var anim_timer: float = 0.0
var anim_fps: float = 10.0

var sfx_jump = preload("res://assets/audio/PlayerJump.wav")
var sfx_damage = preload("res://assets/audio/PlayerDamage.wav")
var sfx_hit = preload("res://assets/audio/PlayerBash.wav")

func _ready() -> void:
	add_to_group(&"player")
	health = max_health
	reset_position = position

	if nail_collision.shape:
		nail_collision.shape = nail_collision.shape.duplicate()

	_load_all_animations()
	play_anim("idle", 8.0)

	nail_collision.disabled = true
	nail_sprite.visible = false

	if not nail_area.body_entered.is_connected(_on_nail_area_body_entered):
		nail_area.body_entered.connect(_on_nail_area_body_entered)

	health_changed.emit(health)
	soul_changed.emit(soul, max_soul)

func _load_all_animations() -> void:
	animations["idle"] = _load_animation_frames("idle")
	animations["walk"] = _load_animation_frames("walk")
	animations["jump"] = _load_animation_frames_range("jump", 1, 9)
	animations["fall"] = _load_animation_frames_range("jump", 10, 12)
	animations["double_jump"] = _load_animation_frames("double_jump")
	animations["dash"] = _load_animation_frames("dash")
	animations["wall_slide"] = _load_animation_frames("wall_slide")
	animations["hurt"] = _load_animation_frames("hurt")
	animations["attack"] = _load_animation_frames("attack")

func _load_animation_frames(dir_name: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var i := 1
	while true:
		var path := "res://assets/sprites/player/%s/%d.PNG" % [dir_name, i]
		if ResourceLoader.exists(path):
			frames.append(load(path) as Texture2D)
			i += 1
		else:
			break
	if frames.is_empty():
		i = 1
		while true:
			var path := "res://assets/sprites/player/%s/%d.png" % [dir_name, i]
			if ResourceLoader.exists(path):
				frames.append(load(path) as Texture2D)
				i += 1
			else:
				break
	return frames

func _load_animation_frames_range(dir_name: String, start_idx: int, end_idx: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(start_idx, end_idx + 1):
		var path := "res://assets/sprites/player/%s/%d.PNG" % [dir_name, i]
		if ResourceLoader.exists(path):
			frames.append(load(path) as Texture2D)
		else:
			path = "res://assets/sprites/player/%s/%d.png" % [dir_name, i]
			if ResourceLoader.exists(path):
				frames.append(load(path) as Texture2D)
	return frames

func play_anim(anim_name: String, fps: float = 10.0) -> void:
	if current_animation_name == "attack" and attack_duration_timer > 0.0 and anim_name in ["idle", "walk", "jump", "fall", "double_jump"]:
		return
	if current_animation_name == anim_name and anim_fps == fps:
		return
	current_animation_name = anim_name
	anim_fps = fps
	anim_frame_index = 0
	anim_timer = 0.0
	if animations.has(anim_name) and not animations[anim_name].is_empty():
		sprite.texture = animations[anim_name][0]

func _process(delta: float) -> void:
	_update_animation(delta)
	_update_attack_window(delta)
	_update_invincibility_flash()

func _physics_process(delta: float) -> void:
	if hit_pause_timer > 0.0:
		hit_pause_timer = max(0.0, hit_pause_timer - delta)
		return

	if event:
		velocity = Vector2.ZERO
		move_and_slide()
		play_anim("idle")
		# gemini3.5: Apply blue glow pulse modulation when sitting at a bench
		var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.005)
		sprite.modulate.r = 0.72 * pulse
		sprite.modulate.g = 0.88 * pulse
		sprite.modulate.b = 1.0
		return
	else:
		if sprite.modulate.r != 1.0 or sprite.modulate.g != 1.0 or sprite.modulate.b != 1.0:
			sprite.modulate.r = 1.0
			sprite.modulate.g = 1.0
			sprite.modulate.b = 1.0

	# gemini3.5: Debug cheat to unlock all abilities instantly for testing (supports F1 or U keys)
	if Input.is_physical_key_pressed(KEY_F1) or Input.is_physical_key_pressed(KEY_U):
		var added_any := false
		for ab in [ABILITY_DASH, ABILITY_DOUBLE_JUMP, ABILITY_VENGEFUL_SPIRIT]:
			if not _has_ability(ab):
				abilities.append(ab)
				added_any = true
		if added_any:
			var game = get_tree().get_first_node_in_group(&"game")
			if game and game.hud:
				game.hud.show_unlock_message("DEBUG: ALL ABILITIES UNLOCKED!")
			print("DEBUG: All abilities unlocked via F1!")

	_update_common_timers(delta)

	var move_input := Input.get_axis("left", "right")
	var wall_sum := _get_wall_sum()

	if _try_cast_spell():
		pass

	if _handle_focus(delta):
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			play_anim("idle", 8.0)
			current_jumps = 0
			_apply_gravity(delta, true)
			_apply_horizontal(0.0, walk_speed, ground_acceleration, ground_deceleration, delta)

			if move_input != 0.0:
				current_state = State.RUN
			elif jump_buffer_timer > 0.0:
				_perform_jump()
			elif not is_on_floor():
				current_state = State.FALL
			elif _try_start_dash(move_input):
				pass

		State.RUN:
			play_anim("walk", 12.0)
			current_jumps = 0
			_apply_gravity(delta, true)
			_apply_horizontal(move_input, walk_speed, ground_acceleration, ground_deceleration, delta)

			if move_input == 0.0:
				current_state = State.IDLE
			elif jump_buffer_timer > 0.0:
				_perform_jump()
			elif not is_on_floor():
				current_state = State.FALL
			elif _try_start_dash(move_input):
				pass

		State.JUMP:
			if current_jumps == 2:
				play_anim("double_jump", 12.0)
			else:
				play_anim("jump", 10.0)
			_apply_gravity(delta, velocity.y >= 0.0)
			_apply_horizontal(move_input, air_speed, air_acceleration, air_deceleration, delta)

			if Input.is_action_just_released("jump") and velocity.y < 0.0:
				velocity.y *= vy_multiplier
			if Input.is_action_just_pressed("jump") and _can_double_jump():
				_perform_double_jump()
			elif velocity.y >= 0.0:
				current_state = State.FALL
			elif is_on_floor():
				current_state = State.IDLE
			elif _try_start_dash(move_input):
				pass
			elif wall_sum != 0 and move_input == wall_sum:
				_start_wall_slide(wall_sum)

		State.FALL:
			play_anim("fall", 10.0)
			_apply_gravity(delta, true)
			_apply_horizontal(move_input, air_speed, air_acceleration, air_deceleration, delta)

			if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
				_perform_jump()
			elif Input.is_action_just_pressed("jump") and _can_double_jump():
				_perform_double_jump()
			elif is_on_floor():
				current_state = State.IDLE
			elif _try_start_dash(move_input):
				pass
			elif wall_sum != 0 and move_input == wall_sum:
				_start_wall_slide(wall_sum)

		State.DASH:
			play_anim("dash", 14.0)
			dash_timer -= delta
			velocity.y = 0.0
			velocity.x = facing_direction * dash_speed

			if dash_timer <= 0.0:
				velocity.x *= dash_exit_speed_multiplier
				current_state = State.IDLE if is_on_floor() else State.FALL
			elif Input.is_action_just_pressed("jump"):
				if is_on_floor():
					dash_timer = 0.0
					_perform_jump()
				elif _can_double_jump():
					# gemini3.5: Allow canceling mid-air dash with double jump
					dash_timer = 0.0
					_perform_double_jump()

		State.WALL_SLIDE:
			play_anim("wall_slide", 10.0)
			velocity.y = wall_slide_velocity
			velocity.x = 0.0

			if wall_sum == 0 or move_input == -wall_direction or move_input == 0.0:
				current_state = State.FALL
			elif jump_buffer_timer > 0.0:
				_perform_wall_jump()
			elif is_on_floor():
				current_state = State.IDLE

		State.WALL_JUMP:
			play_anim("jump", 10.0)
			wall_jump_timer -= delta
			_apply_gravity(delta, velocity.y >= 0.0)
			velocity.x = move_toward(velocity.x, -wall_direction * wall_jump_speed_x, air_acceleration * delta)

			if Input.is_action_just_released("jump") and velocity.y < 0.0:
				velocity.y *= vy_multiplier
			# gemini3.5: Allow double jump from active wall jump state
			if Input.is_action_just_pressed("jump") and _can_double_jump():
				_perform_double_jump()
			elif wall_jump_timer <= 0.0:
				current_state = State.FALL
			elif is_on_floor():
				current_state = State.IDLE

		State.HURT:
			play_anim("hurt", 10.0)
			hurt_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, air_deceleration * delta)
			_apply_gravity(delta, true)

			if hurt_timer <= 0.0:
				current_state = State.IDLE if is_on_floor() else State.FALL

		State.FOCUS:
			pass

	sprite.flip_h = facing_direction == 1

	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0 and not (current_state in [State.HURT, State.FOCUS]):
		_perform_attack()

	move_and_slide()

	# gemini3.5: Out-of-bounds safety check. Reset player to safety and take damage if falling off the map.
	if global_position.y > 750.0:
		global_position = reset_position
		velocity = Vector2.ZERO
		take_damage(1, Vector2.UP)

func _update_animation(delta: float) -> void:
	if animations.has(current_animation_name) and not animations[current_animation_name].is_empty():
		var frames: Array = animations[current_animation_name]
		anim_timer += delta
		if anim_timer >= (1.0 / anim_fps):
			anim_timer = 0.0
			anim_frame_index = (anim_frame_index + 1) % frames.size()
			sprite.texture = frames[anim_frame_index]

func _update_attack_window(delta: float) -> void:
	if attack_duration_timer > 0.0:
		attack_duration_timer -= delta
		if attack_duration_timer <= 0.0:
			nail_collision.disabled = true
			nail_sprite.visible = false
			attack_hit_bodies.clear()

func _update_invincibility_flash() -> void:
	if invincible_timer > 0.0:
		sprite.modulate.a = 0.5 if Engine.get_frames_drawn() % 8 < 4 else 1.0
	else:
		sprite.modulate.a = 1.0

func _update_common_timers(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	if is_on_floor():
		coyote_timer = coyote_time
		current_jumps = 0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	attack_cooldown_timer = max(0.0, attack_cooldown_timer - delta)
	invincible_timer = max(0.0, invincible_timer - delta)
	spell_cooldown_timer = max(0.0, spell_cooldown_timer - delta)

func _apply_gravity(delta: float, fast_fall: bool) -> void:
	var current_gravity := fall_gravity if fast_fall else gravity
	velocity.y = min(velocity.y + current_gravity * delta, max_fall_speed)

func _apply_horizontal(move_input: float, speed: float, accel: float, decel: float, delta: float) -> void:
	if move_input != 0.0:
		facing_direction = int(sign(move_input))
		velocity.x = move_toward(velocity.x, move_input * speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

func _get_wall_sum() -> int:
	var is_against_left_wall = left_wall_ray.is_colliding()
	var is_against_right_wall = right_wall_ray.is_colliding()
	return (1 if is_against_right_wall else 0) - (1 if is_against_left_wall else 0)

func _handle_focus(delta: float) -> bool:
	var can_focus := (
		Input.is_action_pressed("focus")
		and is_on_floor()
		and health < max_health
		and soul >= focus_cost
		and not (current_state in [State.HURT, State.DASH, State.WALL_JUMP])
	)

	if not can_focus:
		if current_state == State.FOCUS:
			current_state = State.IDLE
		focus_timer = 0.0
		return false

	current_state = State.FOCUS
	play_anim("idle", 8.0)
	focus_timer += delta
	_apply_gravity(delta, true)
	_apply_horizontal(0.0, walk_speed, ground_acceleration, ground_deceleration, delta)

	if focus_timer >= focus_time and _spend_soul(focus_cost):
		health = min(max_health, health + 1)
		health_changed.emit(health)
		_play_sfx(sfx_hit)
		focus_timer = 0.0
		if health >= max_health or soul < focus_cost:
			current_state = State.IDLE

	return true

func _try_cast_spell() -> bool:
	if not Input.is_action_just_pressed("spell"):
		return false
	if not _has_ability(ABILITY_VENGEFUL_SPIRIT):
		return false
	if spell_cooldown_timer > 0.0 or current_state in [State.HURT, State.FOCUS]:
		return false
	if not _spend_soul(spell_cost):
		return false

	var spirit = VENGEFUL_SPIRIT_SCENE.instantiate()
	spirit.setup(Vector2(facing_direction, 0), spell_damage, self)
	spirit.position = global_position + Vector2(facing_direction * 38.0, -6.0)
	get_parent().add_child(spirit)
	spell_cooldown_timer = spell_cooldown_time
	_play_sfx(sfx_hit)
	return true

func _try_start_dash(move_input: float) -> bool:
	if Input.is_action_just_pressed("dash") and _can_dash():
		_perform_dash(move_input)
		return true
	return false

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
	# gemini3.5: Double jump tracing log
	print("Player: Double Jump performed! velocity.y = ", velocity.y)

func _start_wall_slide(direction: int) -> void:
	current_state = State.WALL_SLIDE
	wall_direction = direction
	# gemini3.5: Reset jumps when wall sliding
	current_jumps = 0

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
	if move_input != 0.0:
		facing_direction = int(sign(move_input))
	dash_timer = dash_time
	dash_cooldown_timer = dash_cooldown
	current_state = State.DASH
	_play_sfx(sfx_jump)

func _can_dash() -> bool:
	return _has_ability(ABILITY_DASH) and dash_cooldown_timer <= 0.0 and current_state != State.WALL_SLIDE

# GPT5.5_LOCK: verified 2026-06-21. Monarch Wings must gate double jump; post-Room3 route depends on this.
func _can_double_jump() -> bool:
	return _has_ability(ABILITY_DOUBLE_JUMP) and current_jumps < 2

func _has_ability(ability: StringName) -> bool:
	# gemini3.5: Robust string comparison for ability checking
	for a in abilities:
		if str(a) == str(ability):
			return true
	return false

# GPT5.5_LOCK: verified 2026-06-21. Keep InputMap "attack" -> _perform_attack -> _configure_nail_hitbox path intact.
func _perform_attack() -> void:
	attack_cooldown_timer = attack_cooldown_time
	attack_duration_timer = attack_duration_time
	attack_hit_bodies.clear()

	var up_input := Input.is_action_pressed("up")
	var down_input := Input.is_action_pressed("down")
	if up_input:
		attack_direction = Vector2.UP
	elif down_input and not is_on_floor():
		attack_direction = Vector2.DOWN
	else:
		attack_direction = Vector2(facing_direction, 0)

	_configure_nail_hitbox()
	nail_collision.disabled = false
	nail_sprite.visible = true
	nail_sprite.modulate = Color(1, 1, 1, 0.92)

	play_anim("attack", 15.0)
	_play_sfx(sfx_hit)

	var tween = create_tween()
	nail_sprite.scale = Vector2(0.25, 0.25)
	tween.tween_property(nail_sprite, "scale", Vector2(0.92, 0.92), attack_duration_time * 0.45)
	tween.tween_property(nail_sprite, "scale", Vector2(0.46, 0.46), attack_duration_time * 0.55)

# GPT5.5_LOCK: verified side/up/down nail hitbox positions and visible slash offset. Preserve collision/visual split.
func _configure_nail_hitbox() -> void:
	var shape := nail_collision.shape as RectangleShape2D
	if attack_direction.x != 0.0:
		nail_area.position = Vector2(56.0 * facing_direction, -4.0)
		nail_sprite.position = Vector2(32.0 * facing_direction, -2.0)
		if shape:
			shape.size = Vector2(90, 42)
	elif attack_direction == Vector2.UP:
		nail_area.position = Vector2(0.0, -58.0)
		nail_sprite.position = Vector2.ZERO
		if shape:
			shape.size = Vector2(48, 96)
	else:
		nail_area.position = Vector2(0.0, 58.0)
		nail_sprite.position = Vector2.ZERO
		if shape:
			shape.size = Vector2(48, 96)

	nail_sprite.rotation = attack_direction.angle()

func _on_nail_area_body_entered(body: Node2D) -> void:
	if attack_duration_timer <= 0.0 or body == self or body in attack_hit_bodies:
		return

	if body.has_method("take_damage"):
		attack_hit_bodies.append(body)
		var attack_name := &"nail_side"
		if attack_direction == Vector2.UP:
			attack_name = &"nail_up"
		elif attack_direction == Vector2.DOWN:
			attack_name = &"nail_down"

		var hit_info = HitInfo.new(attack_name, self, 1, attack_direction, soul_per_nail_hit, false)
		body.take_damage(1, attack_direction, hit_info)
		_apply_nail_recoil()
		_start_hit_pause(hit_pause_time)
		_play_sfx(sfx_hit)

func _apply_nail_recoil() -> void:
	if attack_direction == Vector2.DOWN:
		velocity.y = pogo_bounce_velocity
		current_jumps = 0
		current_state = State.JUMP
	elif attack_direction == Vector2.UP:
		velocity.y = max(velocity.y, up_recoil_force)
	else:
		velocity.x = -facing_direction * side_recoil_force

func _start_hit_pause(duration: float) -> void:
	hit_pause_timer = max(hit_pause_timer, duration)
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(3.0, 0.06)

func gain_soul(amount: int) -> void:
	if amount <= 0:
		return
	soul = clampi(soul + amount, 0, max_soul)
	soul_changed.emit(soul, max_soul)

func _spend_soul(amount: int) -> bool:
	if amount <= 0:
		return true
	if soul < amount:
		return false
	soul = clampi(soul - amount, 0, max_soul)
	soul_changed.emit(soul, max_soul)
	return true

func take_damage(amount: int, dir: Vector2) -> void:
	if invincible_timer > 0.0 or current_state == State.HURT or event:
		return

	focus_timer = 0.0
	health = max(0, health - amount)
	health_changed.emit(health)
	_play_sfx(sfx_damage)

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(12.0, 0.25)

	if health <= 0:
		current_state = State.HURT
		velocity = Vector2.ZERO
		player_died.emit()
		kill.call_deferred()
	else:
		current_state = State.HURT
		hurt_timer = 0.28
		invincible_timer = 1.15
		hurt_knockback_dir = -1.0 if dir.x > 0.0 else 1.0
		velocity = Vector2(hurt_knockback_dir * knockback_force, -250.0)
		# gemini3.5: Reset jumps when taking damage
		current_jumps = 0

func kill() -> void:
	position = reset_position
	health = max_health
	health_changed.emit(health)
	current_state = State.IDLE
	velocity = Vector2.ZERO

	var game_node = get_tree().get_first_node_in_group(&"game")
	if game_node:
		game_node.load_room(MetSys.get_current_room_id())

func on_enter() -> void:
	event = false
	velocity = Vector2.ZERO
	current_state = State.IDLE
	hit_pause_timer = 0.0
	focus_timer = 0.0
	modulate.a = 1.0
	reset_position = position

func _play_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()
