# -- Identity ---------------------------------------------------------------
## 祕密拾取物：給 Soul 並記錄事件
extends Area2D
class_name SecretPickup

# -- Exports ---------------------------------------------------------------
@export var id: String = ""
@export var soul_amount: int = 33
@export var event_name: String = "secret_found"
@export var message: String = "SECRET FOUND"

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	if id.is_empty():
		id = event_name + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y))

	set_meta(&"object_id", StringName(id))
	if MetSys.register_storable_object(self):
		return

	body_entered.connect(_on_body_entered)

# -- Signal Handlers ---------------------------------------------------------------
# GPT5.5_LOCK: verified 2026-06-21. Room5 shortcut reward must grant soul, event, save state.
func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return

	body.gain_soul(soul_amount)
	MetSys.store_object(self)

	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		if not (event_name in game.events):
			game.events.append(event_name)
		if game.hud:
			game.hud.show_unlock_message(message)
		game.save_game()

	set_deferred("monitoring", false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
