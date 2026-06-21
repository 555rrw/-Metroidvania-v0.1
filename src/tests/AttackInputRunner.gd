extends Node

const PLAYER_SCENE := preload("res://src/player/Player.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if not InputMap.has_action(&"attack"):
		push_error("Missing attack input action")
		get_tree().quit(1)
		return

	var event_count := InputMap.action_get_events(&"attack").size()
	if event_count < 3:
		push_error("Attack action should expose X/J/Mouse Left; got %s events" % event_count)
		get_tree().quit(1)
		return

	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	await get_tree().process_frame

	Input.action_press(&"attack")
	await get_tree().physics_frame
	Input.action_release(&"attack")
	await get_tree().process_frame

	if player.attack_duration_timer <= 0.0:
		push_error("Attack key did not start attack_duration_timer")
		get_tree().quit(1)
		return
	if player.nail_collision.disabled:
		push_error("Attack key did not enable nail collision")
		get_tree().quit(1)
		return
	if not player.nail_sprite.visible:
		push_error("Attack key did not show nail slash")
		get_tree().quit(1)
		return

	print("ATTACK_INPUT_VERIFY_OK events=%s direction=%s" % [event_count, player.attack_direction])
	get_tree().quit(0)
