# -- Identity ---------------------------------------------------------------
## 測試 runner：傳送門/陷阱重生安全
extends Node

# -- Constants And Types ---------------------------------------------------------------
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const PORTAL_SCENE := preload("res://src/objects/Portal.tscn")
const SAW_SCENE := preload("res://src/objects/SawTrap.tscn")

# -- Lifecycle ---------------------------------------------------------------
# GPT5.5_LOCK: portal event guard and MovingTrap bounds protect late-room transitions.

func _ready() -> void:
	call_deferred("_run")

# -- Internal Helpers ---------------------------------------------------------------
func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _assert_portal_event_guard() -> void:
	var portal := PORTAL_SCENE.instantiate() as Portal
	var player := PLAYER_SCENE.instantiate() as Player

	player.event = true
	portal._on_body_entered(player)
	if portal._transitioning:
		_fail("Portal transition guard latched while player.event was already true")
		return

	portal.queue_free()
	player.queue_free()
	await get_tree().process_frame

func _assert_saw_ping_pong_bounds() -> void:
	var saw := SAW_SCENE.instantiate() as SawTrap
	saw.position = Vector2(100.0, 200.0)
	saw.move_speed = 180.0
	saw.move_limit = 30.0
	add_child(saw)
	await get_tree().process_frame

	var expected_base := Vector2(100.0, 200.0)
	for _i in range(80):
		saw._process(0.1)
		if saw._base_position != expected_base:
			_fail("SawTrap base position drifted from start position")
			return
		if absf(saw.position.x - expected_base.x) > saw.move_limit + 0.01:
			_fail("SawTrap horizontal ping-pong exceeded move_limit")
			return
		if saw.position.y != expected_base.y:
			_fail("SawTrap horizontal ping-pong changed Y position")
			return

	saw.queue_free()
	await get_tree().process_frame

func _run() -> void:
	await _assert_portal_event_guard()
	await _assert_saw_ping_pong_bounds()
	print("PORTAL_TRAP_SAFETY_VERIFY_OK")
	get_tree().quit(0)
