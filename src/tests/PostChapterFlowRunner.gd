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

func _run() -> void:
	_backup_save()
	_clear_save()

	# GPT5.5_LOCK: verified 2026-06-21. Covers Room3 clear -> Room4 spell -> Room5 secret -> Room1 shortcut.
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
	var spirit := room4.get_node_or_null("SpiritUpgrade") as AbilityUnlock
	var portal_to_room5 := room4.get_node_or_null("PortalToRoom5") as Portal
	if not spirit or not portal_to_room5:
		_fail("Room4 spell reward or PortalToRoom5 missing")
		return
	spirit._on_body_entered(player)
	await get_tree().create_timer(0.35).timeout
	if not (&"vengeful_spirit" in player.abilities):
		_fail("Room4 did not grant Vengeful Spirit")
		return

	_load_room_via_portal(game, portal_to_room5)
	if not await _wait_for_room(game, "Room5"):
		_fail("Room4 PortalToRoom5 did not load Room5")
		return

	var room5 := game.map
	var secret := room5.get_node_or_null("SecretPickup") as SecretPickup
	var shortcut := room5.get_node_or_null("ShortcutReturn") as Portal
	if not secret or not shortcut:
		_fail("Room5 secret or ShortcutReturn missing")
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
