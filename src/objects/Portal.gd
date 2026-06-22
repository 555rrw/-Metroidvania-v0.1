extends Area2D
class_name Portal

@export_file("*.tscn") var target_room: String
@export var target_portal_name: String = ""

var _transitioning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if _transitioning:
		return

	var player = body as Player
	if player.event:
		return

	# GPT5.5_LOCK: portal transition guard must not latch when player already handles another event.
	_transitioning = true
	player.event = true
	player.velocity = Vector2.ZERO

	# Fade out player
	var tween = create_tween()
	tween.tween_property(player, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Load target room
	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		game.target_portal_name = target_portal_name
		game.load_room(target_room)
	_transitioning = false
