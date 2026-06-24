extends Enemy

# -- Identity ---------------------------------------------------------------
## 爬蟲敵人 AI：地面來回巡邏
class_name Crawlid

# -- Exports ---------------------------------------------------------------
@export var walk_speed: float = 70.0
@export var chase_speed: float = 110.0
@export var detect_distance: float = 300.0
@export var edge_safe_distance: float = 20.0
@export var behave_interval_least: float = 1.0
@export var behave_interval_most: float = 3.0

# -- Constants And Types ---------------------------------------------------------------
enum State { IDLE, WALK_LEFT, WALK_RIGHT, CHASE }

# -- Runtime State ---------------------------------------------------------------
var current_state: State = State.IDLE

var state_timer: float = 0.0
var walk_direction: int = 0
var is_chasing: bool = false

# -- Node References ---------------------------------------------------------------
@onready var wall_ray = $WallRay
@onready var ledge_ray = $LedgeRay

# -- Runtime State ---------------------------------------------------------------
# Simple frame animation loop
var frame_timer: float = 0.0

# -- Exports ---------------------------------------------------------------
@export var anim_fps: float = 8.0

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	super._ready()
	enemy_sprite.hframes = 1
	enemy_sprite.vframes = 1
	enemy_sprite.frame = 0
	_pick_next_patrol_state()

# -- Internal Helpers ---------------------------------------------------------------
func _enemy_ai(delta: float) -> void:
	# Apply gravity
	velocity.y += 1500.0 * delta

	# Update edge detection and wall detection

	var hit_wall = wall_ray.is_colliding()
	var near_ledge = not ledge_ray.is_colliding()

	var reach_edge: int = 0
	if is_on_floor() and (hit_wall or near_ledge):
		reach_edge = walk_direction

	# Check distance to player
	var dist_to_player = 9999.0
	var player_dir = 0.0
	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		var player = players[0] as Player
		dist_to_player = abs(player.global_position.x - global_position.x)
		player_dir = sign(player.global_position.x - global_position.x)
		if player_dir == 0.0: player_dir = 1.0
		# Only chase if player is roughly on the same Y level
		if abs(player.global_position.y - global_position.y) > 100.0:
			dist_to_player = 9999.0 # Ignore

	# State switching
	var should_chase = dist_to_player <= detect_distance
	
	if should_chase and not is_chasing:
		is_chasing = true
		current_state = State.CHASE
	elif not should_chase and is_chasing:
		is_chasing = false
		_pick_next_patrol_state()
		
	if not is_chasing:
		state_timer -= delta
		if state_timer <= 0.0:
			_pick_next_patrol_state()

	# Execute State
	match current_state:
		State.IDLE:
			walk_direction = 0
		State.WALK_LEFT:
			if reach_edge == -1:
				walk_direction = 0 # stop at edge
			else:
				walk_direction = -1
		State.WALK_RIGHT:
			if reach_edge == 1:
				walk_direction = 0 # stop at edge
			else:
				walk_direction = 1
		State.CHASE:
			if reach_edge == player_dir:
				walk_direction = 0 # stop at edge even when chasing
			else:
				walk_direction = player_dir

	# Apply Velocity
	velocity.x = walk_direction * (chase_speed if current_state == State.CHASE else walk_speed)

	# Flip sprite and raycasts
	if walk_direction != 0:
		enemy_sprite.flip_h = (walk_direction == 1)
		wall_ray.target_position.x = walk_direction * 25.0
		ledge_ray.position.x = walk_direction * edge_safe_distance

	# Animate frame
	if enemy_sprite.hframes > 1:
		frame_timer += delta
		var current_anim_fps = anim_fps * (1.5 if current_state == State.CHASE else 1.0)
		if walk_direction == 0:
			current_anim_fps = 0.0 # Stop animation when idle
		
		if current_anim_fps > 0.0:
			if frame_timer >= (1.0 / current_anim_fps):
				frame_timer = 0.0
				enemy_sprite.frame = (enemy_sprite.frame + 1) % enemy_sprite.hframes

	move_and_slide()

func _pick_next_patrol_state() -> void:
	state_timer = randf_range(behave_interval_least, behave_interval_most)

	var next_state = randi() % 3
	match next_state:
		0: current_state = State.IDLE
		1: current_state = State.WALK_LEFT
		2: current_state = State.WALK_RIGHT
