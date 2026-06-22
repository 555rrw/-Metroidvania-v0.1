# -- Identity ---------------------------------------------------------------
extends Area2D
class_name SavePoint

# -- Node References ---------------------------------------------------------------
@onready var prompt = $Label
@onready var glow = $Glow
@onready var seat = $Seat

# -- Runtime State ---------------------------------------------------------------
var player_in_range: Player = null
var resting: bool = false

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false
	if glow:
		glow.modulate.a = 0.0

# -- Signal Handlers ---------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body
		prompt.text = "UP: REST"
		prompt.visible = true
		_fade_glow(0.65)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = null
		prompt.visible = false
		_fade_glow(0.0)

# -- Lifecycle ---------------------------------------------------------------
func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("up") and not resting:
		_rest_at_bench()

# -- Internal Helpers ---------------------------------------------------------------
func _rest_at_bench() -> void:
	resting = true

	var player := player_in_range
	if not player:
		resting = false
		return

	player.event = true
	player.velocity = Vector2.ZERO
	player.global_position = global_position + Vector2(-18, -42)
	player.health = player.max_health
	player.health_changed.emit(player.health)
	player.reset_position = global_position + Vector2(-18, -42)

	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		var event_name := "bench_rest_" + str(int(global_position.x)) + "_" + str(int(global_position.y))
		if not (event_name in game.events):
			game.events.append(event_name)
		game.save_game()
		# gemini3.5: Show bench rested notification on HUD
		if game.hud:
			game.hud.show_unlock_message("BENCH RESTED - MAP UPDATED")

	# gemini3.5: Change text prompt to say SAVED!
	prompt.text = "SAVED!"
	prompt.modulate = Color(0.75, 0.92, 1.0, 1.0)
	_fade_glow(1.0)
	if seat:
		var seat_tween := create_tween()
		seat_tween.tween_property(seat, "scale:y", 0.78, 0.12)
		seat_tween.tween_property(seat, "scale:y", 1.0, 0.18)

	await get_tree().create_timer(0.85).timeout
	if player:
		player.event = false
	if player_in_range:
		prompt.text = "UP: REST"
		prompt.modulate = Color.WHITE
		_fade_glow(0.65)
	resting = false

func _fade_glow(alpha: float) -> void:
	if not glow:
		return

	var tween := create_tween()
	tween.tween_property(glow, "modulate:a", alpha, 0.18)
