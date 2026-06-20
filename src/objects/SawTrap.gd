extends Area2D
class_name SawTrap

@export var damage: int = 1
@export var spin_speed: float = 6.0
@export var frame_time: float = 0.08

@onready var sprite: Sprite2D = $Sprite2D

var frames: Array[Texture2D] = []
var frame_index := 0
var frame_timer := 0.0

func _ready() -> void:
	_load_frames()
	if not frames.is_empty():
		sprite.texture = frames[0]
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotation += spin_speed * delta
	if frames.is_empty():
		return
	frame_timer += delta
	if frame_timer >= frame_time:
		frame_timer = 0.0
		frame_index = (frame_index + 1) % frames.size()
		sprite.texture = frames[frame_index]

func _load_frames() -> void:
	frames.clear()
	for i in range(3):
		var path := "res://assets/sprites/hollow_imitation/trap/saw/saw%04d.png" % i
		if ResourceLoader.exists(path):
			frames.append(load(path) as Texture2D)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var dir := (body.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP
		body.take_damage(damage, dir)
