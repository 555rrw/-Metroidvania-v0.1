# SPEC-102 — 升級收集物（加血上限 / 加魂上限 / 骨釘強化）

**先讀 `docs/specs/README_GEMINI.md`。本規格：新增 2 個檔（整檔內容已給，照貼），再改 `Player.gd` 3 處。**
**這是草稿級規格；先做出能用版本，細節之後再調。**

## 目標
做一種「拾取後永久升級」的物件：面具碎片(+1 血上限並補滿)、魂器(+魂上限)、骨釘強化(+1 釘擊傷害)。
用既有的 `events` 清單做持久化（撿過就不再出現），跟 `SecretPickup` 同套機制。

---

## 步驟1：新增 `src/objects/UpgradePickup.gd`（整檔貼上）
```gdscript
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
```

## 步驟2：新增 `src/objects/UpgradePickup.tscn`（整檔貼上）
```
[gd_scene load_steps=4 format=3 uid="uid://bupgrpck0001a"]

[ext_resource type="Script" path="res://src/objects/UpgradePickup.gd" id="1_up"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/light1.png" id="2_up"]

[sub_resource type="CircleShape2D" id="CircleShape2D_up"]
radius = 26.0

[node name="UpgradePickup" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_up")

[node name="Glow" type="Sprite2D" parent="."]
modulate = Color(1.0, 0.85, 0.5, 0.85)
scale = Vector2(0.5, 0.5)
texture = ExtResource("2_up")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_up")
```

## 步驟3：`src/player/Player.gd` — 新增 nail_damage 並讓釘擊用它

### 3a) 新增變數
找到：
```
var geo: int = 0
```
（若還沒做 SPEC-101 而找不到此行，改找 `var soul: int = 0`，在其下加。）
在它下面加：
```
var nail_damage: int = 1
```

### 3b) 讓釘擊傷害用 nail_damage
找到：
```
			var hit_info = HitInfo.new(attack_name, self, 1, attack_direction, soul_per_nail_hit, false)
			body.take_damage(1, attack_direction, hit_info)
```
改成：
```
			var hit_info = HitInfo.new(attack_name, self, nail_damage, attack_direction, soul_per_nail_hit, false)
			body.take_damage(nail_damage, attack_direction, hit_info)
```

## 放置（測試用，架構師之後會指定正式位置）
本規格不要求放進房間；只要檔案能載入、能被實例化即可。驗證時可暫時在 Room6 放一個測試用實例
（架構師會在後續規格指定每個升級物的房間與座標）。

## 驗收條件
1. headless 跑 `res://src/world/Game.tscn` 無 `SCRIPT ERROR`/`Parse Error`。
2. 編輯器能載入 `UpgradePickup.tscn`（不報錯）。
3. （若有放測試實例）撿到 MASK_SHARD 後血格 +1 並補滿；撿過後重進房不再出現。
4. 回報三個 export（kind / soul_bonus / nail_damage 行為）是否如預期。

## 回報
依 `README_GEMINI.md` 第 6 節格式。任何錨點對不上就停下回報。
</content>
