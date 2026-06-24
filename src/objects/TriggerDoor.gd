# -- Identity ---------------------------------------------------------------
## 受開關控制開閉的門
extends StaticBody2D
class_name TriggerDoor

# -- Exports ---------------------------------------------------------------
@export var event_name: String = "switch_door_open"

# -- Node References ---------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# -- Runtime State ---------------------------------------------------------------
var opened := false

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	var game = get_tree().get_first_node_in_group(&"game")
	if game and game.events.has(event_name):
		open(true)

# -- Public API ---------------------------------------------------------------
func open(immediate: bool = false) -> void:
	if opened:
		return
	opened = true
	collision_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if immediate:
		sprite.modulate.a = 0.0
		return

	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "position:y", sprite.position.y - 96.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45)

func on_switch_triggered() -> void:
	# gemini3.5: Changed to open(true) to match DanielDFY's obstacle.SetActive(false) instantaneous behavior
	open(true)
