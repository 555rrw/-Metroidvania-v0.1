# -- Identity ---------------------------------------------------------------
extends Enemy
class_name MantisWarrior

# -- Exports ---------------------------------------------------------------
@export var idle_step_speed: float = 42.0
@export var patrol_distance: float = 70.0
@export var attack_stance := true
@export var stance_forward_offset: float = 8.0
@export var stance_lean_degrees: float = 4.0

# -- Runtime State ---------------------------------------------------------------
var origin_x := 0.0
var patrol_dir := -1.0

# -- Node References ---------------------------------------------------------------
@onready var body_visual: Node2D = $Body

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	super._ready()
	origin_x = global_position.x
	max_health = max(max_health, 3)
	health = max_health
	_apply_facing_visual()

# -- Internal Helpers ---------------------------------------------------------------
func _enemy_ai(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		patrol_dir = -1.0 if player.global_position.x < global_position.x else 1.0
		_apply_facing_visual()
	else:
		if abs(global_position.x - origin_x) > patrol_distance:
			patrol_dir *= -1.0
			_apply_facing_visual()

	velocity.y += 1500.0 * delta
	velocity.x = patrol_dir * idle_step_speed
	move_and_slide()

# GPT5.5_LOCK: verified 2026-06-21 for Room1 flanking combat. Preserve player-facing spear stance.
func _apply_facing_visual() -> void:
	if not body_visual:
		return

	body_visual.scale.x = -0.88 if patrol_dir > 0.0 else 0.88
	body_visual.position.x = patrol_dir * stance_forward_offset if attack_stance else 0.0
	body_visual.rotation_degrees = -patrol_dir * stance_lean_degrees if attack_stance else 0.0
