# -- Identity ---------------------------------------------------------------
## 測試 runner：Room3 Boss 戰
extends Node

# -- Constants And Types ---------------------------------------------------------------
const GAME_SCENE := preload("res://src/world/Game.tscn")

# -- Runtime State ---------------------------------------------------------------
var _save_backup := PackedByteArray()
var _had_save := false

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	call_deferred("_run")

# -- Internal Helpers ---------------------------------------------------------------
func _backup_save() -> void:
	_had_save = FileAccess.file_exists(Game.SAVE_PATH)
	if _had_save:
		_save_backup = FileAccess.get_file_as_bytes(Game.SAVE_PATH)

func _restore_save() -> void:
	if _had_save:

		var file := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_buffer(_save_backup)
		return

	if FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))

func _clear_save() -> void:
	if FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))

func _fail(message: String) -> void:
	_restore_save()
	push_error(message)
	get_tree().quit(1)

func _find_double_jump_reward(root: Node) -> AbilityUnlock:
	if root is AbilityUnlock and (root as AbilityUnlock).ability_name == "double_jump":
		return root as AbilityUnlock

	for child in root.get_children():
		if child is AbilityUnlock and (child as AbilityUnlock).ability_name == "double_jump":
			return child as AbilityUnlock

		var nested := _find_double_jump_reward(child)
		if nested:
			return nested
	return null

func _assert_node(root: Node, path: NodePath, expected_type: String) -> Node:
	var node := root.get_node_or_null(path)
	if not node:
		_fail("Room3 missing node: " + str(path))
		return null
	if not node.is_class(expected_type) and node.get_class() != expected_type:
		var script: Script = node.get_script() as Script
		var global_name: String = script.get_global_name() if script else ""
		if global_name != expected_type:
			_fail("Room3 node has wrong type: %s expected %s got %s/%s" % [path, expected_type, node.get_class(), global_name])
			return null
	return node

func _run() -> void:
	_backup_save()
	_clear_save()

	var game := GAME_SCENE.instantiate() as Game
	game.starting_map = "res://src/world/Room3.tscn"
	game.target_portal_name = "PortalFromRoom2"
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player := game.get_node("Player") as Player
	game.events.clear()
	MetSys.set_save_data()
	player.abilities.clear()
	player.abilities.append(&"dash")
	player.current_jumps = 1
	if player._can_double_jump():
		_fail("Player can double jump before Monarch Wings")
		return

	await get_tree().process_frame
	await get_tree().physics_frame

	var room: Node = game.map
	if not room or room.name != "Room3":
		_fail("Room3 did not load")
		return

	# GPT5.5_LOCK: verified 2026-06-21. Preserve Room3 chapter-scale route + boss unlock chain.
	var background := room.get_node_or_null("Background") as ColorRect
	if not background or background.size.x < 2400.0:
		_fail("Room3 is not a chapter-scale horizontal map")
		return

	var entry_portal := _assert_node(room, "PortalFromRoom2", "Portal") as Portal
	var victory_portal := _assert_node(room, "VictoryPortal", "Portal") as Portal
	var boss := _assert_node(room, "FalseKnight", "FalseKnight") as FalseKnight
	var barrier := _assert_node(room, "BossBarrier", "StaticBody2D") as StaticBody2D
	var dash_gate := _assert_node(room, "DashKnowledgeGate", "AbilityGate") as AbilityGate
	var shortcut_seal := _assert_node(room, "ShortcutSeal", "AbilityGate") as AbilityGate
	var high_gate := _assert_node(room, "HighRelicGate", "AbilityGate") as AbilityGate
	var high_relic := _assert_node(room, "HighRelic", "SecretPickup") as SecretPickup
	var lower_relic := _assert_node(room, "LowerRelic", "SecretPickup") as SecretPickup

	if player.global_position.x <= entry_portal.global_position.x:
		_fail("Player did not spawn inside Room3 from PortalFromRoom2")
		return
	if boss.global_position.x - player.global_position.x < 1500.0:
		_fail("FalseKnight is too close; Room3 no longer reads as a real chapter route")
		return
	if victory_portal.global_position.x <= boss.global_position.x:
		_fail("VictoryPortal must be beyond the boss arena")
		return
	if victory_portal.target_room != "res://src/world/Room4.tscn":
		_fail("VictoryPortal does not target Room4")
		return
	if dash_gate.required_ability != &"dash":
		_fail("DashKnowledgeGate must reinforce Room2 dash progression")
		return
	if shortcut_seal.open_event != &"boss_defeated":
		_fail("ShortcutSeal must open from the boss_defeated event")
		return
	if high_gate.required_ability != &"double_jump":
		_fail("HighRelicGate must require Monarch Wings return logic")
		return
	if high_relic.event_name != "room3_high_relic_found" or lower_relic.event_name != "room3_lower_relic_found":
		_fail("Room3 relic events are not stable")
		return

	boss.take_damage(999, Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().physics_frame

	if not game.events.has("boss_defeated"):
		_fail("FalseKnight death did not record boss_defeated event")
		return

	var reward: AbilityUnlock = null
	for _i in range(10):
		reward = _find_double_jump_reward(room)
		if reward:
			break
		await get_tree().process_frame

	if not reward:
		_fail("FalseKnight death did not spawn double_jump reward")
		return

	reward._on_body_entered(player)
	await get_tree().process_frame
	await get_tree().physics_frame

	if not (&"double_jump" in player.abilities):
		_fail("Double jump reward did not grant ability")
		return

	player.current_jumps = 1
	if not player._can_double_jump():
		_fail("Player cannot double jump after reward")
		return

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(barrier) and barrier.is_inside_tree():
		_fail("BossBarrier did not open after boss_defeated")
		return
	if is_instance_valid(shortcut_seal) and shortcut_seal.is_inside_tree():
		_fail("ShortcutSeal did not open after boss_defeated")
		return

	victory_portal = room.get_node_or_null("VictoryPortal") as Portal
	if not victory_portal:
		_fail("VictoryPortal missing after BossBarrier opened")
		return

	game.target_portal_name = victory_portal.target_portal_name
	game.load_room(victory_portal.target_room)
	await get_tree().process_frame
	await get_tree().physics_frame

	if not game.map or game.map.name != "Room4":
		_fail("VictoryPortal route data did not load Room4")
		return

	_restore_save()
	print("ROOM3_CHAPTER_LOGIC_VERIFY_OK")
	get_tree().quit(0)
