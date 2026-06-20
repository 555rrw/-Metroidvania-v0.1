extends Area2D
class_name Portal

@export_file("*.tscn") var target_room: String
@export var target_portal_name: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.event:
		body.event = true
		body.velocity = Vector2.ZERO

		# Fade out player
		var tween = create_tween()
		tween.tween_property(body, "modulate:a", 0.0, 0.3)
		await tween.finished

		# Set target portal name in Game and load target room
		var game = get_tree().get_first_node_in_group(&"game")
		if game:
			game.target_portal_name = target_portal_name
			game.load_room(target_room)
