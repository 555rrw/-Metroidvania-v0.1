# -- Identity ---------------------------------------------------------------
## 升級收集物：拾取後永久升級（血上限/魂上限/骨釘傷害），用 events 持久化
extends Area2D
class_name UpgradePickup

# -- Exports ---------------------------------------------------------------
enum UpgradeKind { MASK_SHARD, SOUL_VESSEL, NAIL_UPGRADE }
@export var kind: UpgradeKind = UpgradeKind.MASK_SHARD
@export var soul_bonus: int = 22          # 只給 SOUL_VESSEL 用
@export var event_name: String = ""
@export var message: String = "UPGRADE"

# -- Lifecycle ---------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 已撿過就不再出現
	var game = get_tree().get_first_node_in_group(&"game")
	if game and event_name != "" and (event_name in game.events):
		queue_free()

# -- Signal Handlers ---------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	_apply(player)

	var game = get_tree().get_first_node_in_group(&"game")
	if game:
		if event_name != "" and not (event_name in game.events):
			game.events.append(event_name)
		if game.has_method("save_game"):
			game.save_game()
		if game.hud and game.hud.has_method("show_unlock_message"):
			game.hud.show_unlock_message(message)
	queue_free()

# -- Internal Helpers ---------------------------------------------------------------
func _apply(player: Player) -> void:
	match kind:
		UpgradeKind.MASK_SHARD:
			player.max_health += 1
			player.health = player.max_health
			player.health_changed.emit(player.health)
		UpgradeKind.SOUL_VESSEL:
			player.max_soul += soul_bonus
			player.soul_changed.emit(player.soul, player.max_soul)
		UpgradeKind.NAIL_UPGRADE:
			player.nail_damage += 1
