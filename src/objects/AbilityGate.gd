# -- Identity ---------------------------------------------------------------
extends StaticBody2D
class_name AbilityGate

# -- Exports ---------------------------------------------------------------
@export var required_ability: StringName = &"dash"
@export var open_event: StringName = &""
@export var check_interval: float = 0.2

# -- Runtime State ---------------------------------------------------------------
var check_timer: float = 0.0
var opened: bool = false

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	_check_open()

func _process(delta: float) -> void:
	if opened:
		return
	check_timer -= delta
	if check_timer <= 0.0:
		check_timer = check_interval
		_check_open()

# -- Internal Helpers ---------------------------------------------------------------
func _check_open() -> void:
	if opened:
		return

	var should_open := false
	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		var player = players[0] as Player
		if player and required_ability in player.abilities:
			should_open = true

	var game = get_tree().get_first_node_in_group(&"game")
	if game and not open_event.is_empty() and str(open_event) in game.events:
		should_open = true

	if should_open:
		opened = true
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.35)
		tween.tween_callback(queue_free)
