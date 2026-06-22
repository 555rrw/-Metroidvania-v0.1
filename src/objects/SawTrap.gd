extends Area2D
class_name SawTrap

@export var damage: int = 1
@export var spin_speed: float = 6.0
@export var frame_time: float = 0.08

# DanielDFY MovingTrap.cs: optional ping-pong movement
@export_group("Movement (MovingTrap)")
@export var move_speed: float = 0.0  ## Set > 0 to enable ping-pong movement
@export var move_limit: float = 120.0  ## Max distance from start position
@export var move_vertical: bool = false  ## true = move on Y axis, false = X axis

@onready var sprite: Sprite2D = $Sprite2D

var frames: Array[Texture2D] = []
var frame_index := 0
var frame_timer := 0.0

# MovingTrap state
var _base_position := Vector2.ZERO
var _moving_offset := 0.0
var _move_direction := 1.0

func _ready() -> void:
	_base_position = position
	_move_direction = -1.0 if move_speed < 0.0 else 1.0
	_load_frames()
	if not frames.is_empty():
		sprite.texture = frames[0]
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Spin
	rotation += spin_speed * delta

	# Frame animation
	if not frames.is_empty():
		frame_timer += delta
		if frame_timer >= frame_time:
			frame_timer = 0.0
			frame_index = (frame_index + 1) % frames.size()
			sprite.texture = frames[frame_index]

	# DanielDFY MovingTrap.cs: ping-pong movement
	# GPT5.5_LOCK: MovingTrap ping-pong must stay bounded around start position; do not move base position.
	if move_speed != 0.0 and move_limit > 0.0:
		_moving_offset += delta * absf(move_speed) * _move_direction
		if _moving_offset >= move_limit:
			_moving_offset = move_limit
			_move_direction = -1.0
		elif _moving_offset <= -move_limit:
			_moving_offset = -move_limit
			_move_direction = 1.0

		if move_vertical:
			position = Vector2(_base_position.x, _base_position.y + _moving_offset)
		else:
			position = Vector2(_base_position.x + _moving_offset, _base_position.y)

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
	elif body is Enemy and not body.is_dead:
		# DanielDFY Deadly.cs: moving traps also kill enemies
		body.take_damage(body.health, Vector2.UP)
