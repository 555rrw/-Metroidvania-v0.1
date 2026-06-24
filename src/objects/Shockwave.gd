# -- Identity ---------------------------------------------------------------
## 衝擊波：Boss 砸地後沿地面擴散的傷害波
extends Area2D
class_name Shockwave

# -- Exports ---------------------------------------------------------------
@export var speed: float = 360.0
@export var life_time: float = 1.25
@export var damage: int = 1

# -- Runtime State ---------------------------------------------------------------
var direction: int = 1
var timer: float = 0.0

# -- Public API ---------------------------------------------------------------
func setup(p_direction: int, p_speed: float) -> void:
	direction = -1 if p_direction < 0 else 1
	speed = p_speed
	scale.x = direction

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	timer = life_time
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	timer -= delta
	position.x += direction * speed * delta
	if timer <= 0.0:
		queue_free()

# -- Signal Handlers ---------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, Vector2(direction, -0.4))
