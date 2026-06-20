extends Area2D
class_name SavePoint

@onready var prompt = $Label
var player_in_range: Player = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body
		prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = null
		prompt.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("up"):
		# Restore health
		player_in_range.health = player_in_range.max_health
		player_in_range.health_changed.emit(player_in_range.health)
		player_in_range.reset_position = global_position

		# Save game progress
		var game = get_tree().get_first_node_in_group(&"game")
		if game:
			game.save_game()

		# Visual prompt update
		prompt.text = "Saved!"
		var tween = create_tween()
		tween.tween_property(prompt, "modulate:g", 1.0, 1.0)
		await get_tree().create_timer(1.5).timeout
		if player_in_range:
			prompt.text = "Press UP to Rest"
