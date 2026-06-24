# -- Identity ---------------------------------------------------------------
## 復仇之魂法術投射物
extends Area2D
class_name VengefulSpirit

# -- Constants And Types ---------------------------------------------------------------
const HitInfo = preload("res://src/combat/HitInfo.gd")

# -- Exports ---------------------------------------------------------------
@export var speed: float = 720.0
@export var max_distance: float = 760.0
@export var damage: int = 2

# -- Runtime State ---------------------------------------------------------------
var direction: Vector2 = Vector2.RIGHT
var caster: Node = null
var start_position: Vector2 = Vector2.ZERO
var hit_bodies: Array[Node] = []

# -- Public API ---------------------------------------------------------------
func setup(p_direction: Vector2, p_damage: int, p_caster: Node) -> void:
	direction = p_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = p_damage
	caster = p_caster

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	start_position = global_position
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

# -- Signal Handlers ---------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body == caster or body in hit_bodies:
		return
	hit_bodies.append(body)

	if body.has_method("take_damage"):

		var hit_info = HitInfo.new(&"vengeful_spirit", caster, damage, direction, 0, true)
		body.take_damage(damage, direction, hit_info)
	else:
		queue_free()
