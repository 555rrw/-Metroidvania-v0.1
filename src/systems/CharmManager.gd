# -- Identity ---------------------------------------------------------------
## 護符管理器
extends Node

# -- Constants ---------------------------------------------------------------
const CHARMS := {
	&"quick_focus": {
		"name": "迅魂",
		"notch_cost": 1,
		"description": "聚集回血更快"
	},
	&"long_nail": {
		"name": "長釘",
		"notch_cost": 2,
		"description": "釘擊範圍加長"
	},
	&"thick_shell": {
		"name": "厚甲",
		"notch_cost": 2,
		"description": "受擊無敵時間加長"
	},
	&"greedy_soul": {
		"name": "貪魂",
		"notch_cost": 1,
		"description": "每次命中多 +Soul"
	}
}

# -- State ---------------------------------------------------------------
var owned: Array[StringName] = []
var equipped: Array[StringName] = []
var notch_limit: int = 3

# -- Public API ---------------------------------------------------------------
func used_notches() -> int:
	var total := 0
	for id in equipped:
		if id in CHARMS:
			total += CHARMS[id]["notch_cost"]
	return total

func can_equip(id: StringName) -> bool:
	if not (id in owned):
		return false
	if id in equipped:
		return false
	var cost = CHARMS[id]["notch_cost"] if id in CHARMS else 0
	return used_notches() + cost <= notch_limit

func equip(id: StringName) -> void:
	if can_equip(id):
		equipped.append(id)

func unequip(id: StringName) -> void:
	equipped.erase(id)

func has_equipped(id: StringName) -> bool:
	return id in equipped
