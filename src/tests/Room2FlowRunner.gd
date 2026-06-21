extends Node

const GAME_SCENE := preload("res://src/world/Game.tscn")

func _ready() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _run() -> void:
	# gemini3.5: Clean up save file at test startup to avoid auto-freed collectibles
	if FileAccess.file_exists("user://hollow_knight_save.sav"):
		DirAccess.remove_absolute("user://hollow_knight_save.sav")

	var game = GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	await game.load_room("res://src/world/Room2.tscn")
	await get_tree().physics_frame

	var room = game.map
	if not room:
		_fail("Room2 did not load")
		return

	var dash = room.get_node_or_null("DashUpgrade")
	var moving = room.get_node_or_null("MovingPlatform")
	var safe_island = room.get_node_or_null("StaticEnvironment/SafeIsland")
	var gate_ledge = room.get_node_or_null("StaticEnvironment/GateLedge")
	var switch = room.get_node_or_null("SwitchTrigger")
	var door = room.get_node_or_null("TriggerDoor")
	var falling = room.get_node_or_null("FallingTrap")
	var dash_gate = room.get_node_or_null("DashGate")
	var portal = room.get_node_or_null("PortalToRoom3")

	if not dash or not moving or not safe_island or not gate_ledge or not switch or not door or not falling or not dash_gate or not portal:
		_fail("Room2 flow nodes missing")
		return

	if not (dash.global_position.x < moving.global_position.x and moving.global_position.x < safe_island.global_position.x):
		_fail("Room2 reward/platform/safe-island order is broken")
		return
	if not (safe_island.global_position.x < switch.global_position.x and switch.global_position.x < door.global_position.x):
		_fail("Room2 switch must sit after safe island and before door")
		return
	if not (door.global_position.x < dash_gate.global_position.x and dash_gate.global_position.x < portal.global_position.x):
		_fail("Room2 door/gate/exit order is broken")
		return

	var waypoint2 = moving.get_node_or_null("Waypoint2") as Marker2D
	if not waypoint2:
		_fail("MovingPlatform missing Waypoint2")
		return
	var travel_distance = abs(waypoint2.global_position.x - moving.global_position.x)
	if travel_distance > 520.0:
		_fail("MovingPlatform travel too long for readable chapter flow")
		return

	var player = game.get_node("Player") as Player
	if not (&"dash" in player.abilities):
		player.abilities.append(&"dash")
	if dash_gate.has_method("_check_open"):
		dash_gate._check_open()
	await get_tree().process_frame
	if not dash_gate.opened:
		_fail("DashGate did not recognize dash ability")
		return

	switch.turn_on()
	await get_tree().process_frame
	if not door.opened:
		_fail("Switch did not open Room2 door")
		return
	if not falling.triggered:
		_fail("Switch did not trigger Room2 falling trap")
		return
	if not game.events.has("room2_switch_door"):
		_fail("Room2 switch event not recorded")
		return

	print("ROOM2_FLOW_VERIFY_OK")
	get_tree().quit(0)
