# -- Identity ---------------------------------------------------------------
## 測試 runner：Room2 章節流程
extends Node

# -- Constants And Types ---------------------------------------------------------------
const GAME_SCENE := preload("res://src/world/Game.tscn")

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	call_deferred("_run")

# -- Internal Helpers ---------------------------------------------------------------
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
	var unstable_b := room.get_node_or_null("UnstablePlatformB") as UnstablePlatform
	var platform2 := room.get_node_or_null("StaticEnvironment/Platform2") as StaticBody2D
	var platform3 := room.get_node_or_null("StaticEnvironment/Platform3") as StaticBody2D
	var platform4 := room.get_node_or_null("StaticEnvironment/Platform4") as StaticBody2D

	if not dash_unlock or not moving_platform or not unstable or not saw or not switch or not door or not falling or not dash_gate or not portal or not unstable_b or not platform2 or not platform3 or not platform4:
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

	var moving_exit_x := moving_platform.position.x + 260.0
	var route_points: Array[Vector2] = [
		Vector2(600.0, 660.0),
		Vector2(moving_exit_x, moving_platform.position.y - 12.0),
		Vector2(unstable.position.x, unstable.position.y - 10.0),
		Vector2(platform2.position.x, platform2.position.y - 16.0),
		Vector2(unstable_b.position.x, unstable_b.position.y - 10.0),
		Vector2(platform3.position.x, platform3.position.y - 16.0),
		Vector2(platform4.position.x, platform4.position.y - 16.0),
		Vector2(2060.0, 660.0),
	]
	for i in range(route_points.size() - 1):
		var rise: float = route_points[i].y - route_points[i + 1].y
		var horizontal_gap: float = absf(route_points[i + 1].x - route_points[i].x)
		if rise > 105.0:
			_fail("Room2 route needs double jump at step %s; rise=%s" % [i, rise])
			return
		if horizontal_gap > 430.0:
			_fail("Room2 route gap is too wide for single jump + dash at step %s; gap=%s" % [i, horizontal_gap])
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
