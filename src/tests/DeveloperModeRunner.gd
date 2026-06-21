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

func _press(game: Game, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	game._unhandled_input(event)

func _wait_for_room(game: Game, room_name: String) -> bool:
	for _i in range(90):
		await get_tree().process_frame
		await get_tree().physics_frame
		if game.map and game.map.name == room_name:
			return true
	return false

func _run() -> void:
	_backup_save()
	_clear_save()

	var game := GAME_SCENE.instantiate() as Game
	game.starting_map = "res://src/world/Room1.tscn"
	add_child(game)
	if not await _wait_for_room(game, "Room1"):
		_fail("Game did not load Room1")
		return

	if game.developer_mode_open or game.developer_panel.visible:
		_fail("Developer mode should start closed")
		return

	_press(game, KEY_F10)
	await get_tree().process_frame
	if not game.developer_mode_open or not game.developer_panel.visible:
		_fail("F10 did not open developer mode")
		return

	game.hud = null

	_press(game, KEY_3)
	if not await _wait_for_room(game, "Room3"):
		_fail("Developer key 3 did not jump to Room3")
		return
	if not game.developer_info_label.text.contains("Current: Room3"):
		_fail("Developer panel did not update current room after Room3 jump")
		return

	_press(game, KEY_KP_5)
	if not await _wait_for_room(game, "Room5"):
		_fail("Developer keypad 5 did not jump to Room5")
		return

	_press(game, KEY_F10)
	await get_tree().process_frame
	if game.developer_mode_open or game.developer_panel.visible:
		_fail("F10 did not close developer mode")
		return

	_restore_save()
	game.queue_free()
	await get_tree().process_frame
	print("DEVELOPER_MODE_VERIFY_OK")
	get_tree().quit(0)
