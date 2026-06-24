# SPEC-101 — Geo 貨幣系統

**先讀 `docs/specs/README_GEMINI.md`。本規格動 4 個 `.gd` 檔，照「檔案 → 找錨點 → 貼程式」逐步做。**
**全部是 GDScript（用 Tab 縮排，跟周圍一致）。不要動其他邏輯。**

## 目標
敵人死亡給玩家 Geo（貨幣），HUD 顯示 Geo 數量，存讀檔保留 Geo。這是 P1 商店/購買的基礎。

---

## 檔1：`src/player/Player.gd`

### 1a) 新增 signal
找到：
```
signal player_died()
```
在它下面加一行：
```
signal geo_changed(current_geo: int)
```

### 1b) 新增 geo 變數
找到：
```
var soul: int = 0
var abilities: Array[StringName] = []
```
在 `var abilities` 那行**上面**加：
```
var geo: int = 0
```

### 1c) _ready 初始化發信號
找到（在 `_ready` 函式內）：
```
	health_changed.emit(health)
	soul_changed.emit(soul, max_soul)
```
在這兩行下面加：
```
	geo_changed.emit(geo)
```

### 1d) 新增 add_geo 函式
找到：
```
func gain_soul(amount: int) -> void:
	if amount <= 0:
		return
	soul = clampi(soul + amount, 0, max_soul)
	soul_changed.emit(soul, max_soul)
```
在這個函式**正下方**貼上：
```

func add_geo(amount: int) -> void:
	if amount <= 0:
		return
	geo += amount
	geo_changed.emit(geo)
```

---

## 檔2：`src/enemies/Enemy.gd`

### 2a) 新增 geo_reward export
找到：
```
@export var death_burst_color: Color = Color(0.65, 0.74, 0.86, 1.0)
```
在它下面加：
```
@export var geo_reward: int = 9
```

### 2b) 死亡時給 Geo
找到（在 `func die()` 內，最前面）：
```
func die() -> void:
	is_dead = true
	_spawn_death_burst()
```
在 `_spawn_death_burst()` 那行**下面**加：
```
	var geo_target = get_tree().get_first_node_in_group(&"player")
	if geo_target and geo_target.has_method("add_geo"):
		geo_target.add_geo(geo_reward)
```

---

## 檔3：`src/ui/HUD.gd`（執行時建立 Geo 計數，不動 HUD.tscn）

### 3a) 新增狀態變數
找到：
```
# ---- Full-screen Map Overlay ----
var map_overlay: Control = null
```
在 `# ---- Full-screen Map Overlay ----` 那行**上面**加：
```
# ---- Geo Counter ----
var geo_label: Label = null

```

### 3b) _ready 建立 Geo 標籤
找到（在 `_ready` 內）：
```
	_setup_area_title()
	_setup_map_overlay()
```
在這兩行下面加：
```
	_setup_geo_label()
```

### 3c) setup_player 連接信號
找到：
```
	if not player.soul_changed.is_connected(update_soul):
		player.soul_changed.connect(update_soul)
	update_health(player.health)
	update_soul(player.soul, player.max_soul)
```
在 `update_soul(player.soul, player.max_soul)` 那行**下面**加：
```
	if not player.geo_changed.is_connected(update_geo):
		player.geo_changed.connect(update_geo)
	update_geo(player.geo)
```

### 3d) 新增函式（貼在檔案最後）
在 `src/ui/HUD.gd` 最後一行之後，貼上：
```

# ---- Geo Counter ----
func _setup_geo_label() -> void:
	geo_label = Label.new()
	geo_label.name = "GeoLabel"
	geo_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	geo_label.offset_left = 28.0
	geo_label.offset_top = 120.0
	geo_label.add_theme_font_size_override("font_size", 20)
	geo_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55, 1.0))
	geo_label.add_theme_constant_override("outline_size", 4)
	geo_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.9))
	geo_label.text = "GEO 0"
	add_child(geo_label)

func update_geo(current_geo: int) -> void:
	if geo_label:
		geo_label.text = "GEO %d" % current_geo
```

---

## 檔4：`src/world/Game.gd`（存讀檔）

### 4a) 存檔
找到：
```
	save_mgr.set_value("soul", $Player.soul)
	save_mgr.set_value("max_soul", $Player.max_soul)
	save_mgr.set_value("current_room", MetSys.get_current_room_id())
```
在 `set_value("max_soul"...)` 那行**下面**加：
```
	save_mgr.set_value("geo", $Player.geo)
```

### 4b) 讀檔
找到：
```
		$Player.soul = clampi(int(save_mgr.get_value("soul", 0)), 0, $Player.max_soul)
		$Player.health_changed.emit($Player.health)
		$Player.soul_changed.emit($Player.soul, $Player.max_soul)
```
在 `soul_changed.emit(...)` 那行**下面**加：
```
		$Player.geo = int(save_mgr.get_value("geo", 0))
		$Player.geo_changed.emit($Player.geo)
```

---

## 驗收條件
1. headless 跑 `res://src/world/Game.tscn` 無 `SCRIPT ERROR`/`Parse Error`。
2. 進遊戲：HUD 左側健康條下方出現金色 `GEO 0`。
3. 殺一隻敵人（Room1 往右打 Crawlid/矛兵），Geo 數字增加（預設 +9，矛兵可能不同）。
4. 在長椅存檔→關遊戲→重開（從存檔載入），Geo 數字保留。
5. 截圖（含 GEO 數字增加後）存 `.scratch/spec101_geo.png`。

## 回報
依 `README_GEMINI.md` 第 6 節格式；若任何「找錨點」找不到完全一致的字串，**停下回報**，不要硬塞。
</content>
