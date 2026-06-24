# -- Identity ---------------------------------------------------------------
## 抬頭顯示：血量/Soul/區域標題/小地圖/全螢幕地圖/暫停選單
extends Control
class_name HUD

# -- Constants And Types ---------------------------------------------------------------
const SourceArchive = preload("res://src/integration/SourceArchive.gd")
const MINIMAP_SCENE = preload("res://addons/MetroidvaniaSystem/Template/Nodes/Minimap.tscn")

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

# ---- Geo Counter ----
var geo_label: Label = null

# ---- Charm Overlay ----
var charm_overlay: Control = null
var charm_list_container: VBoxContainer = null
var charm_info_label: Label = null
var charm_notch_label: Label = null

# ---- Full-screen Map Overlay ----
var map_overlay: Control = null
var map_minimap: Control = null
var map_area_label: Label = null

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	popup_label.visible = false
	popup_label.modulate.a = 0.0
	pause_overlay.visible = false
	_setup_area_title()
	_setup_map_overlay()
	_setup_geo_label()
	_setup_charm_overlay()
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
	if not player.geo_changed.is_connected(update_geo):
		player.geo_changed.connect(update_geo)
	update_geo(player.geo)

	# Update ability label
	_update_abilities()

# -- Lifecycle ---------------------------------------------------------------
func _process(_delta: float) -> void:
	# Keep abilities text updated
	_update_abilities()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		_toggle_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("charm") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I):
		_toggle_charm()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			get_viewport().set_input_as_handled()

# -- Internal Helpers ---------------------------------------------------------------
func _toggle_pause() -> void:
	# Map, charm and pause are mutually exclusive.
	if (map_overlay and map_overlay.visible) or (charm_overlay and charm_overlay.visible):
		return
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
# CLAUDE4.8_LOCK: area-title banner. Verified 2026-06-24. Do not rewrite without
# preserving behavior (fade in/out on room entry, CJK SystemFont). See docs/claude48_locked_systems.md.
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
	area_title_label.add_theme_font_override("font", _make_cjk_font())
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

# CLAUDE4.8_LOCK: CJK font helper. Default Godot font has no CJK glyphs — both the
# area title and the map screen depend on this. Do not remove. See docs/claude48_locked_systems.md.
# The bundled default font has no CJK glyphs; use an OS font so Chinese text
# renders. Falls back across common TC/SC families.
func _make_cjk_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Microsoft JhengHei", "Microsoft YaHei", "Noto Sans CJK TC",
		"PingFang TC", "Source Han Sans TC", "sans-serif",
	])
	return f

# ---- Full-screen Map Overlay ----
# CLAUDE4.8_LOCK: full-screen map screen (M key). Verified 2026-06-24 incl. real
# keypress. Do not rewrite without preserving: M toggles, pauses game, mutually
# exclusive with pause menu, MetSys Minimap track_position=true area(11,7)
# display_player_location=true. See docs/claude48_locked_systems.md.
# A Hollow Knight-style map screen toggled with the "map" action (M). Built at
# runtime so the HUD scene stays untouched. Reuses the MetSys Minimap, enlarged
# to show the whole world with the current cell highlighted.
func _setup_map_overlay() -> void:
	map_overlay = Control.new()
	map_overlay.name = "MapOverlay"
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	map_overlay.visible = false
	add_child(map_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.9)
	map_overlay.add_child(dim)

	var title := Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 36.0
	title.offset_bottom = 92.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _make_cjk_font())
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	title.text = "地圖"
	map_overlay.add_child(title)

	map_area_label = Label.new()
	map_area_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	map_area_label.offset_top = 86.0
	map_area_label.offset_bottom = 120.0
	map_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_area_label.add_theme_font_override("font", _make_cjk_font())
	map_area_label.add_theme_font_size_override("font_size", 22)
	map_area_label.add_theme_color_override("font_color", Color(0.6, 0.74, 0.9, 0.9))
	map_overlay.add_child(map_area_label)

	var hint := Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -56.0
	hint.offset_bottom = -24.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", _make_cjk_font())
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 0.8))
	hint.text = "M：關閉地圖"
	map_overlay.add_child(hint)

	# Enlarged world map: follows the player's cell and shows a wide window so the
	# whole (currently linear) world fits. The current cell highlight marks "you
	# are here". As the world grows in Phase 2B this window scrolls with the player.
	map_minimap = MINIMAP_SCENE.instantiate()
	map_minimap.track_position = true
	map_minimap.display_player_location = true
	map_minimap.area = Vector2i(11, 7)
	map_overlay.add_child(map_minimap)

	var msize := map_minimap.get_combined_minimum_size()
	var scl: float = clampf(460.0 / maxf(msize.y, 1.0), 1.0, 8.0)
	map_minimap.scale = Vector2(scl, scl)
	var scaled := msize * scl
	var vp := get_viewport_rect().size
	map_minimap.position = (vp - scaled) * 0.5

func _toggle_map() -> void:
	# Map, charm and pause are mutually exclusive.
	if pause_overlay.visible or (charm_overlay and charm_overlay.visible):
		return
	_set_map_open(not map_overlay.visible)

func _set_map_open(open: bool) -> void:
	map_overlay.visible = open
	get_tree().paused = open
	if open and map_area_label and area_title_label:
		# Reuse the last shown area name as the map subtitle.
		map_area_label.text = area_title_label.text

# ---- Geo Counter ----
func _setup_geo_label() -> void:
	geo_label = Label.new()
	geo_label.name = "GeoLabel"
	geo_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	geo_label.offset_left = 28.0
	geo_label.offset_top = 120.0
	geo_label.add_theme_font_size_override("font_size", 20)
	geo_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55, 1.0))
	geo_label.add_theme_constant_override("outline_size", 4)
	geo_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.9))
	geo_label.text = "GEO 0"
	add_child(geo_label)

func update_geo(current_geo: int) -> void:
	if geo_label:
		geo_label.text = "GEO %d" % current_geo

# ---- Charm Overlay ----
func _setup_charm_overlay() -> void:
	charm_overlay = Control.new()
	charm_overlay.name = "CharmOverlay"
	charm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	charm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	charm_overlay.visible = false
	add_child(charm_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.03, 0.05, 0.92)
	charm_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -200
	panel.offset_bottom = 200
	charm_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _make_cjk_font())
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6, 1.0))
	title.text = "護符選單"
	vbox.add_child(title)

	charm_notch_label = Label.new()
	charm_notch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charm_notch_label.add_theme_font_override("font", _make_cjk_font())
	charm_notch_label.add_theme_font_size_override("font_size", 18)
	charm_notch_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
	vbox.add_child(charm_notch_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)

	charm_list_container = VBoxContainer.new()
	charm_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(charm_list_container)

	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", _make_cjk_font())
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.8))
	hint.text = "I：關閉護符選單"
	vbox.add_child(hint)

func _update_charm_ui() -> void:
	if not charm_list_container or not charm_notch_label:
		return

	charm_notch_label.text = "裝備凹槽: %d / %d" % [CharmManager.used_notches(), CharmManager.notch_limit]

	for child in charm_list_container.get_children():
		child.queue_free()

	for charm_id in CharmManager.CHARMS:
		var charm_data = CharmManager.CHARMS[charm_id]
		var name: String = charm_data["name"]
		var cost: int = charm_data["notch_cost"]
		var desc: String = charm_data["description"]

		var is_owned = charm_id in CharmManager.owned
		var is_equipped = CharmManager.has_equipped(charm_id)

		var hbox := HBoxContainer.new()
		charm_list_container.add_child(hbox)

		var name_label := Label.new()
		name_label.add_theme_font_override("font", _make_cjk_font())
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.custom_minimum_size = Vector2(150, 0)
		if is_owned:
			name_label.text = "%s (%d)" % [name, cost]
			name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		else:
			name_label.text = "??? (%d)" % cost
			name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.add_theme_font_override("font", _make_cjk_font())
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_owned:
			desc_label.text = desc
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		else:
			desc_label.text = "未解鎖"
			desc_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
		hbox.add_child(desc_label)

		if is_owned:
			var btn := Button.new()
			btn.add_theme_font_override("font", _make_cjk_font())
			btn.add_theme_font_size_override("font_size", 14)
			if is_equipped:
				btn.text = "卸下"
				btn.add_theme_color_override("font_color", Color(0.95, 0.6, 0.6, 1.0))
			else:
				btn.text = "裝備"
				btn.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6, 1.0))
				if not CharmManager.can_equip(charm_id):
					btn.disabled = true
			btn.pressed.connect(func(): _on_charm_button_pressed(charm_id))
			hbox.add_child(btn)

func _on_charm_button_pressed(charm_id: StringName) -> void:
	if CharmManager.has_equipped(charm_id):
		CharmManager.unequip(charm_id)
	else:
		CharmManager.equip(charm_id)
	_update_charm_ui()
	var game = get_tree().get_first_node_in_group(&"game")
	if game and game.has_method("save_game"):
		game.save_game()

func _toggle_charm() -> void:
	if pause_overlay.visible or (map_overlay and map_overlay.visible):
		return
	_set_charm_open(not charm_overlay.visible)

func _set_charm_open(open: bool) -> void:
	charm_overlay.visible = open
	get_tree().paused = open
	if open:
		_update_charm_ui()
