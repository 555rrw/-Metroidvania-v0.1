# -- Identity ---------------------------------------------------------------
extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
class_name Game

# -- Constants And Types ---------------------------------------------------------------
# Game manager class matching MetSys singleton pattern.

const SaveManager = preload("res://addons/MetroidvaniaSystem/Template/Scripts/SaveManager.gd")
const SourceArchive = preload("res://src/integration/SourceArchive.gd")
const SAVE_PATH = "user://hollow_knight_save.sav"
const DEV_ROOMS := [
	{"key": "1", "name": "Room1", "path": "res://src/world/Room1.tscn"},
	{"key": "2", "name": "Room2", "path": "res://src/world/Room2.tscn"},
	{"key": "3", "name": "Room3", "path": "res://src/world/Room3.tscn"},
	{"key": "4", "name": "Room4", "path": "res://src/world/Room4.tscn"},
	{"key": "5", "name": "Room5", "path": "res://src/world/Room5.tscn"},
	{"key": "6", "name": "Room6", "path": "res://src/world/Room6.tscn"},
]

# CLAUDE4.8_LOCK: area-title map + entry hook. Verified 2026-06-24. Keep the
# scene-path -> title mapping driving HUD.show_area_title on room change.
# See docs/claude48_locked_systems.md. (Titles themselves are placeholders — safe to rename.)
# Hollow Knight-style area titles shown on room entry. Placeholder names themed
# to 神骸世界 — rename freely.
const AREA_TITLES := {
	"res://src/world/Room1.tscn": "神骸十字路",
	"res://src/world/Room2.tscn": "翠綠幽徑",
	"res://src/world/Room3.tscn": "偽王座之廳",
	"res://src/world/Room4.tscn": "魂之聖所",
	"res://src/world/Room5.tscn": "捷徑試煉道",
	"res://src/world/Room6.tscn": "祕藏石室",
}

# -- Exports ---------------------------------------------------------------
@export_file("*.tscn") var starting_map: String = "res://src/world/Room1.tscn"

# State trackers
# ---- Singletons & References ----
static var _singleton: Node = null

# -- Runtime State ---------------------------------------------------------------
# ---- Portal & Room Transition state ----
var target_portal_name: String = ""
# ---- Game Events & Integration ----
var events: Array[String] = []
var source_archive_summary: Dictionary = {}
# ---- Developer / Debug mode state ----
var developer_mode_open: bool = false

var _pending_spawn_position: Vector2 = Vector2.ZERO
# Tracks the last room scene whose area title was shown, so respawning in the
# same room does not re-trigger the banner.
var _last_area_title_path: String = ""

# -- Node References ---------------------------------------------------------------
@onready var hud: HUD = $CanvasLayer/HUD
@onready var developer_panel: Control = $CanvasLayer/DeveloperPanel
@onready var developer_info_label: Label = $CanvasLayer/DeveloperPanel/InfoLabel

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	_singleton = self
	add_to_group(&"game")
	source_archive_summary = SourceArchive.scan()
	_set_developer_mode(false)

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
		events.assign(save_mgr.get_value("events", []))
		$Player.abilities.assign(save_mgr.get_value("abilities", []))
		$Player.max_health = int(save_mgr.get_value("max_health", $Player.max_health))
		$Player.max_soul = int(save_mgr.get_value("max_soul", $Player.max_soul))
		$Player.health = clampi(int(save_mgr.get_value("health", $Player.max_health)), 0, $Player.max_health)
		$Player.soul = clampi(int(save_mgr.get_value("soul", 0)), 0, $Player.max_soul)
		$Player.health_changed.emit($Player.health)
		$Player.soul_changed.emit($Player.soul, $Player.max_soul)

		var current_room = save_mgr.get_value("current_room", "")
		if not current_room.is_empty():
			starting_map = current_room
	else:
		# Save default layout
		MetSys.set_save_data()

	# GPT5.5_LOCK: post-chapter room loads must position player before next physics tick to avoid room bounce.
	# Connect transition callback.
	# CRITICAL: Do NOT use CONNECT_DEFERRED here. The player must be positioned before
	# the next physics frame to avoid spawning inside hazards (spikes/pits).
	room_loaded.connect(_on_room_loaded)

	# Load start map
	load_room(starting_map)

	# Add the MetSys room transition module
	add_module("RoomTransitions.gd")

	# Position tracking coords reset
	await get_tree().physics_frame
	reset_map_starting_coords.call_deferred()

# -- Public API ---------------------------------------------------------------
# Singleton accessor
static func get_singleton() -> Node:
	return _singleton

func reset_map_starting_coords() -> void:
	# MetSys template hook retained for compatibility; this game manages spawn state directly.
	return

# ---- Save / Load System ----
func save_game() -> void:
	var save_mgr = SaveManager.new()
	save_mgr.set_value("events", events)
	save_mgr.set_value("abilities", $Player.abilities)
	save_mgr.set_value("health", $Player.health)
	save_mgr.set_value("max_health", $Player.max_health)
	save_mgr.set_value("soul", $Player.soul)
	save_mgr.set_value("max_soul", $Player.max_soul)
	save_mgr.set_value("current_room", MetSys.get_current_room_id())
	save_mgr.save_as_text(SAVE_PATH)

# Called by Player.gd's out-of-bounds check to safely teleport without damage.
# ---- Spawn Positioning ----
func get_spawn_position() -> Vector2:
	if _pending_spawn_position != Vector2.ZERO:
		return _pending_spawn_position
	if map:

		var spawn_point = map.get_node_or_null("SpawnPoint")
		if spawn_point:
			return spawn_point.global_position
	return $Player.reset_position if $Player else Vector2(120, 300)

# -- Signal Handlers ---------------------------------------------------------------
func _on_room_loaded() -> void:
	# Executed after MetSys instantiates the room.
	# Since room_loaded is NOT deferred, this runs before the next physics frame.

	var room_size := _get_room_size()

	# Apply camera limits before positioning player so camera is ready
	_apply_camera_limits(room_size)

	var target_spawn_pos := _calculate_spawn_position()

	# Store for OOB safety
	_pending_spawn_position = target_spawn_pos

	# Teleport player immediately
	$Player.global_position = target_spawn_pos
	$Player.velocity = Vector2.ZERO
	$Player.on_enter()

	# CRITICAL: Immediately sync MetSys player position so that
	# _physics_tick doesn't see a stale last_player_position from the
	# previous room. Without this, visit_cell() detects a room-scene
	# mismatch between the old cell and the new cell, emits room_changed,
	# and RoomTransitions bounces the player back to the old room.
	MetSys.set_player_position($Player.position)

	# Fade player back in
	$Player.modulate.a = 1.0
	target_portal_name = ""
	_update_developer_panel()
	_show_area_title_for_current_room()

# ---- Area Title ----
# Show the Hollow Knight-style area banner, but only when the room scene actually
# changed (skip same-room respawns and same-scene cell scrolling).
func _show_area_title_for_current_room() -> void:
	if not hud or not map:
		return
	var scene_path := map.scene_file_path
	if scene_path == _last_area_title_path:
		return
	_last_area_title_path = scene_path
	var title: String = AREA_TITLES.get(scene_path, "")
	if not title.is_empty():
		hud.show_area_title(title)

# -- Internal Helpers ---------------------------------------------------------------
# ---- Spawn Calculations ----
func _calculate_spawn_position() -> Vector2:
	var room_size := _get_room_size()

	# Search room children for portals/bench
	if not target_portal_name.is_empty() and map:
		var portals = _find_nodes_of_type(map, "Portal")
		for p in portals:
			if p.name == target_portal_name:
				return _get_portal_exit_position(p, room_size)

	if map:
		var spawn_point = map.get_node_or_null("SpawnPoint")
		if spawn_point:
			return spawn_point.global_position

	# Default to room origin plus a small offset
	if map:
		return map.global_position + Vector2(120, max(120.0, room_size.y - 98.0))

	return Vector2(120, 300)

# -- Lifecycle ---------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			_set_developer_mode(not developer_mode_open)
			get_viewport().set_input_as_handled()
			return

		if developer_mode_open:

			var room_index := _developer_key_to_room_index(event.keycode)
			if room_index >= 0:
				dev_jump_to_room(room_index + 1)
				get_viewport().set_input_as_handled()
				return

# -- Internal Helpers ---------------------------------------------------------------
# ---- Developer Panel ----
func _developer_key_to_room_index(keycode: Key) -> int:
	match keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		KEY_4, KEY_KP_4:
			return 3
		KEY_5, KEY_KP_5:
			return 4
		KEY_6, KEY_KP_6:
			return 5
		_:
			return -1

func _set_developer_mode(open: bool) -> void:
	developer_mode_open = open
	if developer_panel:
		developer_panel.visible = developer_mode_open
	_update_developer_panel()

# -- Public API ---------------------------------------------------------------
# ---- Developer Warps ----
func dev_jump_to_room(room_number: int) -> void:
	var index := room_number - 1
	if index < 0 or index >= DEV_ROOMS.size():
		push_warning("Developer room number out of range: %s" % room_number)
		return

	var room: Dictionary = DEV_ROOMS[index]
	target_portal_name = ""
	var player := $Player as Player
	if player:
		player.event = false
		player.velocity = Vector2.ZERO
		player.modulate.a = 1.0
		player.current_state = Player.State.IDLE
		player.invincible_timer = 2.0
		player._kill_pending_room_load = ""

	load_room(str(room["path"]))
	if hud:
		hud.show_unlock_message("DEV WARP: " + str(room["name"]))
	_update_developer_panel()

# -- Internal Helpers ---------------------------------------------------------------
func _update_developer_panel() -> void:
	if not developer_info_label:
		return

	var current_room := "None"
	if map:
		current_room = map.name

	var lines := [
		"DEV MODE - F10 toggle",
		"Current: " + current_room,
		"",
	]
	for room in DEV_ROOMS:
		lines.append("%s  %s" % [room["key"], room["name"]])
	developer_info_label.text = "\n".join(lines)

# ---- Camera & Room Transitions ----
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
