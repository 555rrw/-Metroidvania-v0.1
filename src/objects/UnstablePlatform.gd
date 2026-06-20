extends AnimatableBody2D
class_name UnstablePlatform

@export var trigger_delay: float = 0.28
@export var respawn_delay: float = 2.5
@export var frame_time: float = 0.07
@export var respawn: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea

var frames: Array[Texture2D] = []
var triggered := false
var base_position := Vector2.ZERO

func _ready() -> void:
	base_position = position
	_load_frames()
	if not frames.is_empty():
		sprite.texture = frames[0]
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _load_frames() -> void:
	frames.clear()
	for i in range(6):
		var path := "res://assets/sprites/hollow_imitation/platform/unstable_mid/dream_plat_mid%04d.png" % i
		if ResourceLoader.exists(path):
			frames.append(load(path) as Texture2D)

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body is Player:
		trigger()

func trigger() -> void:
	if triggered:
		return
	triggered = true
	_run_collapse.call_deferred()

func _run_collapse() -> void:
	var jitter := create_tween()
	for i in range(4):
		jitter.tween_property(sprite, "offset", Vector2(4, 0), trigger_delay / 8.0)
		jitter.tween_property(sprite, "offset", Vector2(-4, 0), trigger_delay / 8.0)
	jitter.tween_property(sprite, "offset", Vector2.ZERO, trigger_delay / 8.0)
	await jitter.finished

	if not frames.is_empty():
		for frame in frames:
			sprite.texture = frame
			await get_tree().create_timer(frame_time).timeout

	collision_shape.set_deferred("disabled", true)
	trigger_area.set_deferred("monitoring", false)
	var fall := create_tween().set_parallel(true)
	fall.tween_property(self, "position:y", base_position.y + 42.0, 0.22)
	fall.tween_property(sprite, "modulate:a", 0.0, 0.22)
	await fall.finished

	if not respawn:
		queue_free()
		return

	await get_tree().create_timer(respawn_delay).timeout
	position = base_position
	sprite.offset = Vector2.ZERO
	sprite.modulate.a = 1.0
	if not frames.is_empty():
		sprite.texture = frames[0]
	collision_shape.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", true)
	triggered = false
