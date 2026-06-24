# -- Identity ---------------------------------------------------------------
extends Control
class_name HUD

# -- Constants And Types ---------------------------------------------------------------
const SourceArchive = preload("res://src/integration/SourceArchive.gd")

# -- Node References ---------------------------------------------------------------
@onready var masks_container = $MasksContainer
@onready var soul_fill = $SoulMeter/SoulFill
@onready var soul_label = $SoulMeter/SoulLabel
@onready var popup_label = $PopupLabel
@onready var ability_label = $AbilityLabel
@onready var source_label = $SourceLabel
@onready var pause_overlay = $PauseOverlay
@onready var continue_button: Button = $PauseOverlay/MenuPanel/ContinueButton
@onready var menu_button: Button = $PauseOverlay/MenuPanel/MenuButton
@onready var quit_button: Button = $PauseOverlay/MenuPanel/QuitButton

# -- Runtime State ---------------------------------------------------------------
var texture_full = preload("res://assets/sprites/UI/health_full.png")
var texture_empty = preload("res://assets/sprites/UI/health_empty.png")

var player_ref: Player = null

# ---- Area Title Banner ----
var area_title_label: Label = null
var _area_title_tween: Tween = null

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	popup_label.visible = false
	popup_label.modulate.a = 0.0
	pause_overlay.visible = false
	_setup_area_title()
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Find player and connect signals

	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		setup_player(players[0] as Player)

# -- Public API ---------------------------------------------------------------
func setup_player(player: Player) -> void:
	player_ref = player
	if not player.health_changed.is_connected(update_health):
		player.health_changed.connect(update_health)
	if not player.soul_changed.is_connected(update_soul):
		player.soul_changed.connect(update_soul)
	update_health(player.health)
	update_soul(player.soul, player.max_soul)

	# Update ability label
	_update_abilities()

# -- Lifecycle ---------------------------------------------------------------
func _process(_delta: float) -> void:
	# Keep abilities text updated
	_update_abilities()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			get_viewport().set_input_as_handled()

# -- Internal Helpers ---------------------------------------------------------------
func _toggle_pause() -> void:
	_set_paused(not pause_overlay.visible)

func _set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	get_tree().paused = paused
	if paused:
		continue_button.grab_focus()

# -- Signal Handlers ---------------------------------------------------------------
func _on_continue_pressed() -> void:
	_set_paused(false)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

# -- Public API ---------------------------------------------------------------
func update_health(current_health: int) -> void:
	# Clear or update TextureRect children

	var children = masks_container.get_children()
	for i in range(children.size()):
		var mask = children[i] as TextureRect
		if i < current_health:
			mask.texture = texture_full
		else:
			mask.texture = texture_empty

func update_soul(current_soul: int, max_soul: int) -> void:
	if not soul_fill:
		return

	var pct := 0.0
	if max_soul > 0:
		pct = clamp(float(current_soul) / float(max_soul), 0.0, 1.0)
	soul_fill.size.x = 156.0 * pct
	if soul_label:
		soul_label.text = "SOUL %02d" % current_soul

# -- Internal Helpers ---------------------------------------------------------------
func _update_abilities() -> void:
	if not player_ref:
		return

	var text = "Abilities: "
	if player_ref.abilities.is_empty():
		text += "None"
	else:
		var list = []
		for a in player_ref.abilities:
			list.append(str(a).to_upper())
		text += ", ".join(list)
	ability_label.text = text

# -- Public API ---------------------------------------------------------------
func show_unlock_message(message: String) -> void:
	popup_label.text = message
	popup_label.visible = true
	popup_label.modulate.a = 0.0
	popup_label.scale = Vector2(0.5, 0.5)
	popup_label.pivot_offset = popup_label.size / 2.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(popup_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(popup_label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.8).timeout

	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(popup_label, "modulate:a", 0.0, 0.3)
	tween_out.tween_property(popup_label, "scale", Vector2(0.8, 0.8), 0.3)
	await tween_out.finished
	popup_label.visible = false

func set_source_summary(summary: Dictionary) -> void:
	var totals := SourceArchive.totals(summary)
	source_label.text = "Sources: %d repos / %d files indexed" % [totals.repos, totals.files]

# ---- Area Title Banner ----
# Hollow Knight-style area name that fades in/out when the player enters a new room.
func _setup_area_title() -> void:
	area_title_label = Label.new()
	area_title_label.name = "AreaTitleLabel"
	area_title_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	area_title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Sit in the upper third so the banner does not cover the player/combat.
	area_title_label.offset_bottom = -220.0
	area_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The bundled default font has no CJK glyphs; use an OS font so Chinese area
	# names render. Falls back across common TC/SC families.
	var cjk_font := SystemFont.new()
	cjk_font.font_names = PackedStringArray([
		"Microsoft JhengHei", "Microsoft YaHei", "Noto Sans CJK TC",
		"PingFang TC", "Source Han Sans TC", "sans-serif",
	])
	area_title_label.add_theme_font_override("font", cjk_font)
	area_title_label.add_theme_font_size_override("font_size", 46)
	area_title_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	area_title_label.add_theme_constant_override("outline_size", 8)
	area_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.9))
	area_title_label.modulate.a = 0.0
	add_child(area_title_label)

func show_area_title(title: String) -> void:
	if not area_title_label or title.strip_edges().is_empty():
		return
	area_title_label.text = title
	if _area_title_tween and _area_title_tween.is_valid():
		_area_title_tween.kill()
	area_title_label.modulate.a = 0.0
	_area_title_tween = create_tween()
	_area_title_tween.tween_property(area_title_label, "modulate:a", 1.0, 0.7)
	_area_title_tween.tween_interval(1.8)
	_area_title_tween.tween_property(area_title_label, "modulate:a", 0.0, 1.1)
