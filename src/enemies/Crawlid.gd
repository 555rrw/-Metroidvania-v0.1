extends Enemy
class_name Crawlid

@export var speed: float = 70.0
var walk_direction: int = -1

@onready var wall_ray = $WallRay
@onready var ledge_ray = $LedgeRay

# Simple frame animation loop
var frame_timer: float = 0.0
@export var anim_fps: float = 8.0

func _ready() -> void:
	super._ready()
	# Set hframes for the sprite sheet
	enemy_sprite.hframes = 4
	enemy_sprite.vframes = 1

func _enemy_ai(delta: float) -> void:
	# Apply gravity
	velocity.y += 1500.0 * delta

	# Horizontal movement
	velocity.x = walk_direction * speed

	# Check for wall or ledge
	var hit_wall = wall_ray.is_colliding()
	var near_ledge = not ledge_ray.is_colliding()

	if is_on_floor() and (hit_wall or near_ledge):
		walk_direction = -walk_direction
		# Flip raycasts to point in new direction
		wall_ray.target_position.x = walk_direction * 25.0
		ledge_ray.position.x = walk_direction * 20.0

	# Flip sprite
	enemy_sprite.flip_h = (walk_direction == 1)

	# Animate frame
	frame_timer += delta
	if frame_timer >= (1.0 / anim_fps):
		frame_timer = 0.0
		enemy_sprite.frame = (enemy_sprite.frame + 1) % enemy_sprite.hframes

	move_and_slide()
