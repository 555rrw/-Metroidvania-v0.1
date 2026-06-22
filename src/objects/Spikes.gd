# -- Identity ---------------------------------------------------------------
extends Area2D
class_name Spikes

# -- Exports ---------------------------------------------------------------
# Damage dealt per tick. Player invincibility frames prevent instant re-death loops.
@export var damage: int = 999

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# -- Signal Handlers ---------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# The Player's take_damage already handles invincible_timer checks.
		# This call will be safely ignored during invincibility frames,
		# preventing the death loop even if player respawns on spikes.
		body.take_damage(damage, Vector2.UP)
	elif body is Enemy and not body.is_dead:
		# DanielDFY Deadly.cs: spikes also instantly kill enemies
		body.take_damage(body.health, Vector2.UP)
