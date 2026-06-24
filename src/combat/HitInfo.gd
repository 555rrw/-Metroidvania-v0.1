# -- Identity ---------------------------------------------------------------
## 攻擊命中資訊資料類（傷害/方向/Soul增益/來源）
extends RefCounted
class_name HitInfo

# -- Runtime State ---------------------------------------------------------------
var attack_name: StringName
var source: Node
var damage: int
var direction: Vector2
var soul_gain: int
var breaks_armor: bool

# -- Internal Helpers ---------------------------------------------------------------
func _init(
		p_attack_name: StringName = &"nail",
		p_source: Node = null,
		p_damage: int = 1,
		p_direction: Vector2 = Vector2.RIGHT,
		p_soul_gain: int = 0,
		p_breaks_armor: bool = false
) -> void:
	attack_name = p_attack_name
	source = p_source
	damage = p_damage
	direction = p_direction
	soul_gain = p_soul_gain
	breaks_armor = p_breaks_armor
