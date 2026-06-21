extends Enemy
class_name MantisWarrior

@export var idle_step_speed: float = 42.0
@export var patrol_distance: float = 70.0

var origin_x := 0.0
var patrol_dir := -1.0

@onready var body_visual: Node2D = $Body

func _ready() -> void:
	super._ready()
	origin_x = global_position.x
	max_health = max(max_health, 3)
	health = max_health

func _enemy_ai(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		patrol_dir = -1.0 if player.global_position.x < global_position.x else 1.0
		if body_visual:
			body_visual.scale.x = -0.88 if patrol_dir > 0.0 else 0.88
	else:
		if abs(global_position.x - origin_x) > patrol_distance:
			patrol_dir *= -1.0
			if body_visual:
				body_visual.scale.x = -0.88 if patrol_dir > 0.0 else 0.88

	velocity.y += 1500.0 * delta
	velocity.x = patrol_dir * idle_step_speed
	move_and_slide()
