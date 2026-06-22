# -- Identity ---------------------------------------------------------------
extends StaticBody2D
class_name SwitchTrigger

# -- Exports ---------------------------------------------------------------
@export var event_name: String = "switch_door_open"
@export var door_path: NodePath
@export var trap_path: NodePath
@export var trigger_targets: Array[NodePath] = []

# -- Node References ---------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# -- Runtime State ---------------------------------------------------------------
var triggered := false

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	var game = get_tree().get_first_node_in_group(&"game")
	if game and game.events.has(event_name):
		_mark_triggered(true)

# -- Public API ---------------------------------------------------------------
func take_damage(_amount: int, _attack_dir: Vector2, _hit_info = null) -> void:
	turn_on()

func turn_on() -> void:
	if triggered:
		return
	_mark_triggered(false)

	var game = get_tree().get_first_node_in_group(&"game")
	if game and not game.events.has(event_name):
		game.events.append(event_name)
	var paths: Array[NodePath] = []
	if not door_path.is_empty():
		paths.append(door_path)
	if not trap_path.is_empty():
		paths.append(trap_path)
	paths.append_array(trigger_targets)
	for path in paths:
		var target := get_node_or_null(path)
		if not target:
			continue
		if target.has_method("on_switch_triggered"):
			target.on_switch_triggered()
		elif target.has_method("trigger"):
			target.trigger()
		elif target.has_method("open"):
			target.open()

# -- Internal Helpers ---------------------------------------------------------------
func _mark_triggered(immediate: bool) -> void:
	triggered = true
	collision_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	sprite.flip_h = true
	sprite.modulate = Color(0.55, 0.75, 1.0, 1.0)
	if not immediate:

		var tween := create_tween()
		tween.tween_property(sprite, "rotation", -0.45, 0.14)
