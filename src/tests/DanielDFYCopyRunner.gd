# -- Identity ---------------------------------------------------------------
## 測試 runner：DanielDFY 功能對照驗證
extends Node

# -- Constants And Types ---------------------------------------------------------------
const ROOM4 := "res://src/world/Room4.tscn"
const ROOM5 := "res://src/world/Room5.tscn"
const SOURCE_SCENE := "Assets/Scenes/Level2.unity"

# -- Lifecycle ---------------------------------------------------------------
# GPT5.5_LOCK: Room4/Room5 after Chapter 3 must visibly carry DanielDFY Level2 visual and gameplay layers.

func _ready() -> void:
	call_deferred("_run")

# -- Internal Helpers ---------------------------------------------------------------
func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _script_global_name(node: Node) -> String:
	var script := node.get_script() as Script
	return script.get_global_name() if script else ""

func _count_sprites(node: Node) -> int:
	var count := 1 if node is Sprite2D else 0
	for child in node.get_children():
		count += _count_sprites(child)
	return count

func _assert_room_copy(room_path: String, expected_room_name: String) -> bool:
	var packed := load(room_path) as PackedScene
	if not packed:
		_fail("Could not load " + room_path)
		return false

	var room := packed.instantiate()
	if room.name != expected_room_name:
		_fail("%s loaded as wrong node %s" % [room_path, room.name])
		return false

	var visual := room.get_node_or_null("DanielDFYLevel2VisualCopy")
	var gameplay := room.get_node_or_null("DanielDFYLevel2GameplayCopy")
	var spawn := room.get_node_or_null("SpawnPoint") as Node2D
	if not visual or not gameplay:
		_fail(expected_room_name + " missing DanielDFY visual/gameplay copy nodes")
		return false
	if not spawn:
		_fail(expected_room_name + " missing SpawnPoint")
		return false
	if spawn.position.x < 170.0:
		_fail(expected_room_name + " SpawnPoint overlaps entry portal; player can immediately bounce out")
		return false
	if not visual.visible or not gameplay.visible:
		_fail(expected_room_name + " DanielDFY visual/gameplay copy must be visible")
		return false

	if visual.get_meta(&"source_scene", "") != SOURCE_SCENE:
		_fail(expected_room_name + " visual copy source mismatch")
		return false
	if gameplay.get_meta(&"source_scene", "") != SOURCE_SCENE:
		_fail(expected_room_name + " gameplay copy source mismatch")
		return false
	if gameplay.get_meta(&"gameplay_only", false) != true:
		_fail(expected_room_name + " gameplay copy missing gameplay_only metadata")
		return false
	if gameplay.get_node_or_null("RoomInstance"):
		_fail(expected_room_name + " gameplay copy must not contain nested RoomInstance")
		return false

	var sprite_count := _count_sprites(visual)
	if sprite_count != 45:
		_fail("%s visual copy expected 45 Level2 sprites, got %d" % [expected_room_name, sprite_count])
		return false

	var imported_objects := gameplay.get_node_or_null("ImportedObjects")
	if not imported_objects:
		_fail(expected_room_name + " gameplay copy missing ImportedObjects")
		return false
	if imported_objects.get_child_count() != 22:
		_fail("%s gameplay copy expected 22 Level2 objects, got %d" % [expected_room_name, imported_objects.get_child_count()])
		return false

	var static_bodies := 0
	var spikes := 0
	var switches := 0
	var doors := 0
	for child in imported_objects.get_children():
		if child is StaticBody2D:
			static_bodies += 1
		var global_name := _script_global_name(child)
		if global_name == "Spikes":
			spikes += 1
		elif global_name == "SwitchTrigger":
			switches += 1
		elif global_name == "TriggerDoor":
			doors += 1

	if static_bodies != 19 or spikes != 3 or switches != 1 or doors != 1:
		_fail("%s gameplay mismatch: static=%d spikes=%d switches=%d doors=%d" % [expected_room_name, static_bodies, spikes, switches, doors])
		return false

	room.queue_free()
	return true

func _run() -> void:
	if not _assert_room_copy(ROOM4, "Room4"):
		return
	if not _assert_room_copy(ROOM5, "Room5"):
		return
	print("DANIELDFY_COPY_VERIFY_OK")
	get_tree().quit(0)
