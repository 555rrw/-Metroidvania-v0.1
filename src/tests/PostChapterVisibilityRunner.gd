extends Node

const GAME_SCENE := preload("res://src/world/Game.tscn")
const ROOMS := [
	{"name": "Room4", "path": "res://src/world/Room4.tscn"},
	{"name": "Room5", "path": "res://src/world/Room5.tscn"},
]

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
	elif FileAccess.file_exists(Game.SAVE_PATH):
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

func _count_visible_canvas(node: Node, rect: Rect2) -> int:
	var count := 0
	if node is CanvasItem and (node as CanvasItem).is_visible_in_tree():
		var item := node as CanvasItem
		if rect.has_point(item.get_global_transform().origin):
			count += 1
	for child in node.get_children():
		count += _count_visible_canvas(child, rect)
	return count

func _assert_direct_room_entry(room: Dictionary) -> void:
	var game := GAME_SCENE.instantiate() as Game
	game.starting_map = str(room["path"])
	add_child(game)
	if not await _wait_for_room(game, str(room["name"])):
		_fail("Could not direct-load " + str(room["name"]))
		return

	await get_tree().create_timer(0.5).timeout
	if not game.map or game.map.name != str(room["name"]):
		_fail("%s bounced to another room after spawn" % room["name"])
		return

	var spawn := game.map.get_node_or_null("SpawnPoint") as Node2D
	var player := game.get_node("Player") as Player
	if not spawn or player.global_position.distance_to(spawn.global_position) > 24.0:
		_fail("%s player did not stay on safe post-chapter spawn" % room["name"])
		return

	var camera := game.get_node("PlayerCamera") as Camera2D
	var view_size := get_viewport().get_visible_rect().size / camera.zoom
	var rect := Rect2(camera.global_position - view_size * 0.5, view_size)
	var visible_count := _count_visible_canvas(game.map, rect)
	if visible_count < 50:
		_fail("%s visible content too low after direct entry: %d" % [room["name"], visible_count])
		return

	game.queue_free()
	await get_tree().process_frame

func _run() -> void:
	# GPT5.5_LOCK: direct entry after Chapter 3 must not spawn inside entry portal or show an empty room.
	_backup_save()
	_clear_save()
	for room in ROOMS:
		await _assert_direct_room_entry(room)
	_restore_save()
	print("POST_CHAPTER_VISIBILITY_VERIFY_OK")
	get_tree().quit(0)
