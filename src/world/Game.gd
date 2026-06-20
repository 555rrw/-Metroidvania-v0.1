extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
class_name Game
# Game manager class matching MetSys singleton pattern.

const SaveManager = preload("res://addons/MetroidvaniaSystem/Template/Scripts/SaveManager.gd")
const SourceArchive = preload("res://src/integration/SourceArchive.gd")
const SAVE_PATH = "user://hollow_knight_save.sav"

@export_file("*.tscn") var starting_map: String = "res://src/world/Room1.tscn"

# State trackers
static var _singleton: Node = null
var target_portal_name: String = ""
var events: Array[String] = []
var source_archive_summary: Dictionary = {}

@onready var hud: HUD = $CanvasLayer/HUD

func _ready() -> void:
	_singleton = self
	add_to_group(&"game")
	source_archive_summary = SourceArchive.scan()

	# Clear MetSys state
	MetSys.reset_state()

	# Register player node with MetSysGame base class
	set_player($Player)

	# Initialize HUD player references
	if hud:
		hud.setup_player($Player)
		hud.set_source_summary(source_archive_summary)

	# Load save if present
	if FileAccess.file_exists(SAVE_PATH):
		var save_mgr = SaveManager.new()
		save_mgr.load_from_text(SAVE_PATH)

		# Restore player and game state
		events.assign(save_mgr.get_value("events"))
		$Player.abilities.assign(save_mgr.get_value("abilities"))
		$Player.health = save_mgr.get_value("health")
		$Player.health_changed.emit($Player.health)

		var current_room = save_mgr.get_value("current_room")
		if not current_room.is_empty():
			starting_map = current_room
	else:
		# Save default layout
		MetSys.set_save_data()

	# Connect transition callback
	room_loaded.connect(_on_room_loaded, CONNECT_DEFERRED)

	# Load start map
	load_room(starting_map)

	# Add the MetSys room transition module
	add_module("RoomTransitions.gd")

	# Position tracking coords reset
	await get_tree().physics_frame
	reset_map_starting_coords.call_deferred()

# Singleton accessor
static func get_singleton() -> Node:
	return _singleton

func reset_map_starting_coords() -> void:
	pass

func save_game() -> void:
	var save_mgr = SaveManager.new()
	save_mgr.set_value("events", events)
	save_mgr.set_value("abilities", $Player.abilities)
	save_mgr.set_value("health", $Player.health)
	save_mgr.set_value("current_room", MetSys.get_current_room_id())
	save_mgr.save_as_text(SAVE_PATH)

func _on_room_loaded() -> void:
	# Executed after MetSys instantiates the room
	# Locate the target portal or spawn location
	var target_spawn_pos = Vector2.ZERO
	var found_spawn = false
	var room_size := _get_room_size()

	_apply_camera_limits(room_size)

	# Search room children for portals/bench
	if not target_portal_name.is_empty() and map:
		# Search for portal with matching name
		var portals = _find_nodes_of_type(map, "Portal")
		for p in portals:
			if p.name == target_portal_name:
				target_spawn_pos = _get_portal_exit_position(p, room_size)
				found_spawn = true
				break

	if not found_spawn and map:
		var spawn_point = map.get_node_or_null("SpawnPoint")
		if spawn_point:
			target_spawn_pos = spawn_point.global_position
			found_spawn = true

	if not found_spawn and map:
		# Default to room origin plus a small offset
		target_spawn_pos = map.global_position + Vector2(120, max(120.0, room_size.y - 98.0))

	# Teleport player
	$Player.global_position = target_spawn_pos
	$Player.velocity = Vector2.ZERO
	$Player.on_enter()

	# Fade player back in
	$Player.modulate.a = 1.0
	target_portal_name = ""

func _get_room_size() -> Vector2:
	var fallback := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1280),
		ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	)
	if not map:
		return fallback

	var background = map.get_node_or_null("Background")
	if background is Control:
		var size := (background as Control).size
		if size.x > 0.0 and size.y > 0.0:
			return size

	return fallback

func _apply_camera_limits(room_size: Vector2) -> void:
	var camera := $PlayerCamera as Camera2D
	if not camera or not map:
		return

	var origin := map.global_position
	var view_size := get_viewport().get_visible_rect().size / camera.zoom
	var room_width: float = max(room_size.x, view_size.x)
	var room_height: float = max(room_size.y, view_size.y)

	camera.limit_left = int(origin.x)
	camera.limit_top = int(origin.y)
	camera.limit_right = int(origin.x + room_width)
	camera.limit_bottom = int(origin.y + room_height)
	camera.reset_smoothing()

func _get_portal_exit_position(portal: Node2D, room_size: Vector2) -> Vector2:
	var room_origin := map.global_position if map else Vector2.ZERO
	var room_mid_x := room_origin.x + room_size.x * 0.5
	var exit_x := 80.0 if portal.global_position.x < room_mid_x else -80.0
	return portal.global_position + Vector2(exit_x, 0.0)

# Recursive helper to find nodes by type name
func _find_nodes_of_type(root_node: Node, type_name: String) -> Array[Node]:
	var results: Array[Node] = []
	if root_node.is_class(type_name) or root_node.get_class() == type_name or root_node.get_script() and root_node.get_script().get_global_name() == type_name:
		results.append(root_node)
	for i in range(root_node.get_child_count()):
		results.append_array(_find_nodes_of_type(root_node.get_child(i), type_name))
	return results
