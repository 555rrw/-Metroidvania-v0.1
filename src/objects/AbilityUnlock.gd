# -- Identity ---------------------------------------------------------------
## 能力解鎖拾取物（dash/二段跳/法術）
extends Area2D
class_name AbilityUnlock

# -- Exports ---------------------------------------------------------------
@export var ability_name: String = "dash" # "dash" or "double_jump"
@export var id: String = ""

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	if id.is_empty():
		id = ability_name + "_collectible_" + str(int(global_position.x)) + "_" + str(int(global_position.y))

	set_meta(&"object_id", StringName(id))
	if MetSys.register_storable_object(self):
		return

	body_entered.connect(_on_body_entered)

# -- Signal Handlers ---------------------------------------------------------------
# GPT5.5_LOCK: verified 2026-06-21. Ability pickups must persist before post-chapter portals continue.
func _on_body_entered(body: Node2D) -> void:
	if body is Player:

		var ability_sym = StringName(ability_name)
		if not (ability_sym in body.abilities):
			body.abilities.append(ability_sym)

		MetSys.store_object(self)

		# Show unlock message on HUD
		var game = get_tree().get_first_node_in_group(&"game")
		if game and game.hud:
			game.hud.show_unlock_message(_unlock_message())
		if game:
			game.save_game()

		# Fade out and free
		set_deferred("monitoring", false)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(queue_free)

# -- Internal Helpers ---------------------------------------------------------------
func _unlock_message() -> String:
	match ability_name:
		"dash":
			return "MOTHWING CLOAK UNLOCKED"
		"double_jump":
			return "MONARCH WINGS UNLOCKED"
		"vengeful_spirit":
			return "VENGEFUL SPIRIT LEARNED"
		_:
			return "UNLOCKED " + ability_name.to_upper()
