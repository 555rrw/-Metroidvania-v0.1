extends Node

const GAME_SCENE := preload("res://src/world/Game.tscn")

func _ready() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _run() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player := game.get_node("Player") as Player
	game.events.clear()
	player.abilities.clear()

	await game.load_room("res://src/world/Room2.tscn")
	await get_tree().process_frame
	await get_tree().physics_frame

	var room: Node = game.map
	if not room:
		_fail("Room2 did not load")
		return

	var dash_unlock := room.get_node_or_null("DashUpgrade") as AbilityUnlock
	var moving_platform := room.get_node_or_null("MovingPlatform") as MovingPlatform
	var unstable := room.get_node_or_null("UnstablePlatformA") as UnstablePlatform
	var saw: Node = room.get_node_or_null("SawTrap")
	var switch := room.get_node_or_null("SwitchTrigger") as SwitchTrigger
	var door := room.get_node_or_null("TriggerDoor") as TriggerDoor
	var falling := room.get_node_or_null("FallingTrap") as FallingTrap
	var dash_gate := room.get_node_or_null("DashGate") as AbilityGate
	var portal: Node = room.get_node_or_null("PortalToRoom3")

	if not dash_unlock or not moving_platform or not unstable or not saw or not switch or not door or not falling or not dash_gate or not portal:
		_fail("Room2 DanielDFY flow nodes missing")
		return

	if dash_unlock.position.x >= moving_platform.position.x:
		_fail("Dash reward should appear before moving platform gap")
		return
	if moving_platform.waypoints.size() < 2:
		_fail("MovingPlatform should have DanielDFY-style patrol waypoint")
		return
	if unstable.position.x <= moving_platform.position.x:
		_fail("Unstable platform pressure should appear after moving platform")
		return
	if not (switch.position.x < door.position.x and door.position.x < dash_gate.position.x and dash_gate.position.x < portal.position.x):
		_fail("Exit order should be switch -> door -> dash gate -> portal")
		return

	switch.turn_on()
	await get_tree().process_frame
	if not door.opened:
		_fail("Switch did not open TriggerDoor")
		return
	if not falling.triggered:
		_fail("Switch did not trigger FallingTrap")
		return
	if not game.events.has("room2_switch_door"):
		_fail("Switch event was not recorded")
		return

	unstable.trigger()
	await get_tree().process_frame
	if not unstable.triggered:
		_fail("UnstablePlatform did not enter triggered state")
		return

	player.abilities.append(&"dash")
	dash_gate._check_open()
	await get_tree().process_frame
	if not dash_gate.opened:
		_fail("DashGate did not open after dash ability")
		return

	print("ROOM2_FLOW_VERIFY_OK")
	get_tree().quit(0)
