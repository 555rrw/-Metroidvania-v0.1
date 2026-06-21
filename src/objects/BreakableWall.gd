# gemini3.5: Entire script created for spell-gated breakable wall
extends StaticBody2D
class_name BreakableWall


const HitInfo = preload("res://src/combat/HitInfo.gd")
var is_broken := false

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var sfx_clink = $SFXClink
@onready var sfx_shatter = $SFXShatter
@onready var particles = $Particles

func take_damage(_amount: int, _attack_dir: Vector2, hit_info = null) -> void:
	if is_broken:
		return
	
	if hit_info and hit_info.attack_name == &"vengeful_spirit":
		is_broken = true
		_shatter()
	else:
		# Play a clink sound to show it is invulnerable to standard nail attacks
		if sfx_clink:
			sfx_clink.play()

func _shatter() -> void:
	# Trigger screen shake
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(16.0, 0.28)
	
	# Disable physics/collision and hide sprite
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	
	# Emit particles
	if particles:
		particles.emitting = true
	
	# Play explosion/shatter sound
	if sfx_shatter:
		sfx_shatter.play()
		await sfx_shatter.finished
	
	queue_free()
