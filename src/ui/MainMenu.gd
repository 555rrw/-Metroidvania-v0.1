extends Control
class_name MainMenu

const GAME_SCENE := "res://src/world/Game.tscn"
const SAVE_PATH := "user://hollow_knight_save.sav"

@onready var start_button: Button = $MenuPanel/StartButton
@onready var load_button: Button = $MenuPanel/LoadButton
@onready var quit_button: Button = $MenuPanel/QuitButton
@onready var pointer: TextureRect = $MenuPanel/Pointer

var buttons: Array[Button] = []

func _ready() -> void:
	get_tree().paused = false
	buttons = [start_button, load_button, quit_button]
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button in buttons:
		button.focus_entered.connect(_sync_pointer)
	start_button.grab_focus()
	_sync_pointer()

func _process(_delta: float) -> void:
	_sync_pointer()

func _on_start_pressed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_load_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _sync_pointer() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and focused in buttons:
		pointer.global_position = focused.global_position + Vector2(-46.0, 9.0)
