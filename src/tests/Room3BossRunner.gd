extends Node

const GAME_SCENE := preload("res://src/world/Game.tscn")

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

	var entry_portal := room.get_node_or_null("PortalFromRoom2") as Portal
	var victory_portal := room.get_node_or_null("VictoryPortal") as Portal
	var boss := room.get_node_or_null("FalseKnight") as FalseKnight
	var barrier := room.get_node_or_null("BossBarrier") as StaticBody2D
	if not entry_portal or not victory_portal or not boss or not barrier:
		_fail("Room3 missing entry portal, victory portal, boss, or barrier")
		return

	if player.global_position.x <= entry_portal.global_position.x:
		_fail("Player did not spawn inside Room3 from PortalFromRoom2")
		return
	if player.global_position.distance_to(boss.global_position) > 620.0:
		_fail("FalseKnight starts too far from player spawn")
		return
	if victory_portal.target_room != "res://src/world/Room4.tscn":
		_fail("VictoryPortal does not target Room4")
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

	player = game.get_node("Player") as Player
	victory_portal = room.get_node_or_null("VictoryPortal") as Portal
	if not victory_portal:
		_fail("VictoryPortal missing after BossBarrier opened")
		return

	player.global_position = victory_portal.global_position
	victory_portal._on_body_entered(player)
	await get_tree().create_timer(0.45).timeout
	await get_tree().process_frame
	await get_tree().physics_frame

	if not game.map or game.map.name != "Room4":
		_fail("VictoryPortal did not transition to Room4")
		return

	_restore_save()
	print("ROOM3_BOSS_VERIFY_OK")
	get_tree().quit(0)
