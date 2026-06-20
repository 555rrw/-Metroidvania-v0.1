extends Control
class_name HUD

const SourceArchive = preload("res://src/integration/SourceArchive.gd")

@onready var masks_container = $MasksContainer
@onready var soul_fill = $SoulMeter/SoulFill
@onready var soul_label = $SoulMeter/SoulLabel
@onready var popup_label = $PopupLabel
@onready var ability_label = $AbilityLabel
@onready var source_label = $SourceLabel

var texture_full = preload("res://assets/sprites/UI/health_full.png")
var texture_empty = preload("res://assets/sprites/UI/health_empty.png")

var player_ref: Player = null

func _ready() -> void:
	popup_label.visible = false
	popup_label.modulate.a = 0.0

	# Find player and connect signals
	var players = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		setup_player(players[0] as Player)

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

func _process(_delta: float) -> void:
	# Keep abilities text updated
	_update_abilities()

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
