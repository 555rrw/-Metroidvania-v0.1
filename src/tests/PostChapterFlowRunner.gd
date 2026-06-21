extends Node

const GAME_SCENE := preload("res://src/world/Game.tscn")
const HitInfo := preload("res://src/combat/HitInfo.gd")

var _save_backup := PackedByteArray()
var _had_save := false

func _ready() -> void:
	call_deferred("_run")

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

func _wait_for_room(game: Game, room_name: String) -> bool:
	for _i in range(120):
		await get_tree().process_frame
		await get_tree().physics_frame
		if game.map and game.map.name == room_name:
			return true
	return false

func _find_ability(root: Node, ability_name: String) -> AbilityUnlock:
	if root is AbilityUnlock and (root as AbilityUnlock).ability_name == ability_name:
		return root as AbilityUnlock

	for child in root.get_children():
		var found := _find_ability(child, ability_name)
		if found:
			return found
	return null

func _load_room_via_portal(game: Game, portal: Portal) -> void:
	game.target_portal_name = portal.target_portal_name
	game.load_room(portal.target_room)

func _assert_node(root: Node, path: NodePath, expected_type: String) -> Node:
	var node := root.get_node_or_null(path)
	if not node:
		_fail("%s missing node: %s" % [root.name, path])
		return null
	if not node.is_class(expected_type) and node.get_class() != expected_type:
		var script: Script = node.get_script() as Script
		var global_name: String = script.get_global_name() if script else ""
		if global_name != expected_type:
			_fail("%s node has wrong type: %s expected %s got %s/%s" % [root.name, path, expected_type, node.get_class(), global_name])
			return null
	return node

func _assert_chapter_width(room: Node, label: String) -> void:
	var background := room.get_node_or_null("Background") as ColorRect
	if not background or background.size.x < 2400.0:
		_fail(label + " is not a chapter-scale DanielDFY route")

func _run() -> void:
	_backup_save()
	_clear_save()

	# GPT5.5_LOCK: verified 2026-06-21. Covers Room3 clear -> DanielDFY-style Room4/Room5 -> Room1 shortcut.
	var game := GAME_SCENE.instantiate() as Game
	game.starting_map = "res://src/world/Room3.tscn"
	game.target_portal_name = "PortalFromRoom2"
	add_child(game)
	if not await _wait_for_room(game, "Room3"):
		_fail("Could not start post-chapter flow at Room3")
		return

	var player := game.get_node("Player") as Player
	game.hud = null
	game.events.clear()
	MetSys.set_save_data()
	player.abilities.clear()
	player.abilities.append(&"dash")

	var room3 := game.map
	var boss := room3.get_node_or_null("FalseKnight") as FalseKnight
	var victory_portal := room3.get_node_or_null("VictoryPortal") as Portal
	if not boss or not victory_portal:
		_fail("Room3 boss or VictoryPortal missing")
		return

	boss.take_damage(999, Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().physics_frame
	if not game.events.has("boss_defeated"):
		_fail("Room3 boss_defeated event missing")
		return

	var wings: AbilityUnlock = null
	for _i in range(12):
		wings = _find_ability(room3, "double_jump")
		if wings:
			break
		await get_tree().process_frame
	if not wings:
		_fail("Room3 Monarch Wings reward missing")
		return
	wings._on_body_entered(player)
	await get_tree().create_timer(0.35).timeout
	if not (&"double_jump" in player.abilities):
		_fail("Monarch Wings did not persist on player")
		return

	_load_room_via_portal(game, victory_portal)
	if not await _wait_for_room(game, "Room4"):
		_fail("Room3 VictoryPortal did not load Room4")
		return

	var room4 := game.map
	_assert_chapter_width(room4, "Room4")
	var moving_platform := _assert_node(room4, "MovingPlatform", "MovingPlatform") as MovingPlatform
	var unstable_a := _assert_node(room4, "UnstablePlatformA", "UnstablePlatform") as UnstablePlatform
	var unstable_b := _assert_node(room4, "UnstablePlatformB", "UnstablePlatform") as UnstablePlatform
	var unstable_c := _assert_node(room4, "UnstablePlatformC", "UnstablePlatform") as UnstablePlatform
	var saw := _assert_node(room4, "SawTrap", "SawTrap") as SawTrap
	var falling_trap := _assert_node(room4, "SanctumFallingTrap", "FallingTrap") as FallingTrap
	var sanctum_switch := _assert_node(room4, "SanctumSwitch", "SwitchTrigger") as SwitchTrigger
	var sanctum_door := _assert_node(room4, "SanctumDoor", "TriggerDoor") as TriggerDoor
	var spell_gate := _assert_node(room4, "SpellExitGate", "AbilityGate") as AbilityGate
	var practice_wall := _assert_node(room4, "SpiritPracticeWall", "BreakableWall") as BreakableWall
	var sanctum_gunner := _assert_node(room4, "SanctumGunner", "Gunner") as Gunner
	var sanctum_relic := _assert_node(room4, "SanctumRelic", "SecretPickup") as SecretPickup
	var spirit := room4.get_node_or_null("SpiritUpgrade") as AbilityUnlock
	var portal_to_room5 := room4.get_node_or_null("PortalToRoom5") as Portal
	if not spirit or not portal_to_room5:
		_fail("Room4 spell reward or PortalToRoom5 missing")
		return
	if not moving_platform.get_node_or_null("OuterPoint"):
		_fail("Room4 MovingPlatform missing DanielDFY patrol waypoint")
		return
	if not unstable_a or not unstable_b or not unstable_c or not saw or not falling_trap or not sanctum_gunner or not sanctum_relic:
		_fail("Room4 DanielDFY trap/enemy/resource chain incomplete")
		return
	if spell_gate.required_ability != &"vengeful_spirit":
		_fail("Room4 SpellExitGate must require Vengeful Spirit")
		return
	spell_gate._check_open()
	await get_tree().process_frame
	if spell_gate.opened:
		_fail("Room4 SpellExitGate opened before Vengeful Spirit")
		return
	spirit._on_body_entered(player)
	await get_tree().create_timer(0.35).timeout
	if not (&"vengeful_spirit" in player.abilities):
		_fail("Room4 did not grant Vengeful Spirit")
		return

	practice_wall.sfx_clink = null
	practice_wall.sfx_shatter = null
	practice_wall.particles = null
	practice_wall.take_damage(1, Vector2.RIGHT, HitInfo.new(&"nail_side", player, 1, Vector2.RIGHT, 0, false))
	await get_tree().process_frame
	if practice_wall.is_broken:
		_fail("Room4 SpiritPracticeWall broke from nail")
		return
	practice_wall.take_damage(2, Vector2.RIGHT, HitInfo.new(&"vengeful_spirit", player, 2, Vector2.RIGHT, 0, true))
	var room4_wall_broke := practice_wall.is_broken
	await get_tree().process_frame
	if not room4_wall_broke:
		_fail("Room4 SpiritPracticeWall did not break from Vengeful Spirit")
		return

	sanctum_switch.turn_on()
	await get_tree().process_frame
	if not sanctum_door.opened or not game.events.has("room4_sanctum_switch"):
		_fail("Room4 SanctumSwitch did not open door and record event")
		return
	spell_gate._check_open()
	await get_tree().process_frame
	if not spell_gate.opened:
		_fail("Room4 SpellExitGate did not open after Vengeful Spirit")
		return

	_load_room_via_portal(game, portal_to_room5)
	if not await _wait_for_room(game, "Room5"):
		_fail("Room4 PortalToRoom5 did not load Room5")
		return

	var room5 := game.map
	_assert_chapter_width(room5, "Room5")
	var spell_entry_gate := _assert_node(room5, "SpellGate", "AbilityGate") as AbilityGate
	var spell_shortcut_wall := _assert_node(room5, "SpellShortcutWall", "BreakableWall") as BreakableWall
	var room5_moving := _assert_node(room5, "MovingPlatform", "MovingPlatform") as MovingPlatform
	var room5_unstable_a := _assert_node(room5, "UnstablePlatformA", "UnstablePlatform") as UnstablePlatform
	var room5_unstable_b := _assert_node(room5, "UnstablePlatformB", "UnstablePlatform") as UnstablePlatform
	var room5_unstable_c := _assert_node(room5, "UnstablePlatformC", "UnstablePlatform") as UnstablePlatform
	var saw_a := _assert_node(room5, "SawTrapA", "SawTrap") as SawTrap
	var saw_b := _assert_node(room5, "SawTrapB", "SawTrap") as SawTrap
	var shortcut_switch := _assert_node(room5, "ShortcutSwitch", "SwitchTrigger") as SwitchTrigger
	var shortcut_door := _assert_node(room5, "ShortcutDoor", "TriggerDoor") as TriggerDoor
	var shortcut_seal := _assert_node(room5, "ShortcutSeal", "AbilityGate") as AbilityGate
	var shortcut_trap := _assert_node(room5, "ShortcutFallingTrap", "FallingTrap") as FallingTrap
	var shortcut_gunner := _assert_node(room5, "ShortcutGunner", "Gunner") as Gunner
	var secret := room5.get_node_or_null("SecretPickup") as SecretPickup
	var shortcut := room5.get_node_or_null("ShortcutReturn") as Portal
	if not secret or not shortcut:
		_fail("Room5 secret or ShortcutReturn missing")
		return
	if not room5_moving.get_node_or_null("OuterPoint"):
		_fail("Room5 MovingPlatform missing DanielDFY patrol waypoint")
		return
	if not room5_unstable_a or not room5_unstable_b or not room5_unstable_c or not saw_a or not saw_b or not shortcut_trap or not shortcut_gunner:
		_fail("Room5 DanielDFY trap/enemy chain incomplete")
		return
	if shortcut.target_room != "res://src/world/Room1.tscn" or shortcut.target_portal_name != "PortalToRoom5":
		_fail("Room5 ShortcutReturn route must land on Room1 shortcut portal")
		return
	if spell_entry_gate.required_ability != &"vengeful_spirit":
		_fail("Room5 SpellGate must require Vengeful Spirit")
		return
	spell_entry_gate._check_open()
	await get_tree().process_frame
	if not spell_entry_gate.opened:
		_fail("Room5 SpellGate did not open with Vengeful Spirit")
		return

	spell_shortcut_wall.sfx_clink = null
	spell_shortcut_wall.sfx_shatter = null
	spell_shortcut_wall.particles = null
	spell_shortcut_wall.take_damage(1, Vector2.RIGHT, HitInfo.new(&"nail_side", player, 1, Vector2.RIGHT, 0, false))
	await get_tree().process_frame
	if spell_shortcut_wall.is_broken:
		_fail("Room5 SpellShortcutWall broke from nail")
		return
	spell_shortcut_wall.take_damage(2, Vector2.RIGHT, HitInfo.new(&"vengeful_spirit", player, 2, Vector2.RIGHT, 0, true))
	var room5_wall_broke := spell_shortcut_wall.is_broken
	await get_tree().process_frame
	if not room5_wall_broke:
		_fail("Room5 SpellShortcutWall did not break from Vengeful Spirit")
		return

	shortcut_seal._check_open()
	await get_tree().process_frame
	if shortcut_seal.opened:
		_fail("Room5 ShortcutSeal opened before switch event")
		return
	shortcut_switch.turn_on()
	await get_tree().process_frame
	if not shortcut_door.opened or not game.events.has("room5_shortcut_door"):
		_fail("Room5 ShortcutSwitch did not open door and record event")
		return
	shortcut_seal._check_open()
	await get_tree().process_frame
	if not shortcut_seal.opened:
		_fail("Room5 ShortcutSeal did not open from switch event")
		return
	var soul_before := player.soul
	secret._on_body_entered(player)
	await get_tree().create_timer(0.3).timeout
	if not game.events.has("shortcut_secret_found"):
		_fail("Room5 secret event missing")
		return
	if player.soul <= soul_before:
		_fail("Room5 secret did not grant soul")
		return

	_load_room_via_portal(game, shortcut)
	if not await _wait_for_room(game, "Room1"):
		_fail("Room5 ShortcutReturn did not load Room1")
		return

	var room1 := game.map
	var shortcut_gate := room1.get_node_or_null("ShortcutGate") as AbilityGate
	var breakable_wall := room1.get_node_or_null("BreakableWall") as BreakableWall
	if not shortcut_gate or not breakable_wall:
		_fail("Room1 shortcut gate or spell wall missing after Room5 return")
		return
	breakable_wall.sfx_clink = null
	breakable_wall.sfx_shatter = null
	breakable_wall.particles = null

	shortcut_gate._check_open()
	await get_tree().process_frame
	if not shortcut_gate.opened:
		_fail("Room1 shortcut gate did not open with Monarch Wings")
		return

	breakable_wall.take_damage(1, Vector2.RIGHT, HitInfo.new(&"nail_side", player, 1, Vector2.RIGHT, 0, false))
	await get_tree().process_frame
	if breakable_wall.is_broken:
		_fail("BreakableWall broke from nail; spell gate logic broken")
		return

	breakable_wall.take_damage(2, Vector2.RIGHT, HitInfo.new(&"vengeful_spirit", player, 2, Vector2.RIGHT, 0, true))
	var wall_broke := breakable_wall.is_broken
	await get_tree().create_timer(0.8).timeout
	if not wall_broke:
		_fail("BreakableWall did not break from Vengeful Spirit")
		return

	_restore_save()
	game.queue_free()
	await get_tree().process_frame
	print("POST_CHAPTER_FLOW_VERIFY_OK")
	get_tree().quit(0)
