# SPEC-001 — Room3 美術提升（偽王座之廳）

**先讀 `docs/specs/README_GEMINI.md`。只改 `src/world/Room3.tscn` 這一個檔。**

## 目標
Room3 目前背景太暗、裝飾太少（裸色塊感）。比照 Room2 的修法，把它變成有氛圍的「偽王座之廳」：
提亮既有背景、加入柱/燈/結構裝飾。**不動任何碰撞、敵人、Boss、傳送門、閘門、地板位置**。

## 禁改範圍
- 不要動 `StaticEnvironment`（地板/牆/平台碰撞）、`FalseKnight`、`Crawlid*`、`Vengefly*`、
  `PortalFromRoom2`、`VictoryPortal`、所有 `*Gate`/`*Seal`/`*Barrier`、`AcidPool`、`*Relic`、`SpawnPoint`。
- 只准：改既有 3 個背景 sprite 的 `modulate`、新增 3 個 `ext_resource`、新增裝飾 sprite 節點、改 `load_steps`。

## 步驟

### 1) 改檔頭 load_steps
把第 1 行
```
[gd_scene load_steps=15 format=3 uid="uid://cxsc37k2bvdh3"]
```
改成
```
[gd_scene load_steps=18 format=3 uid="uid://cxsc37k2bvdh3"]
```

### 2) 新增 3 個 ext_resource
找到這一行（既有的最後一個 Texture ext_resource）：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/ruind_window_01.png" id="12_r3"]
```
在它**正下方**加三行：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column1.png" id="13_r3"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column2.png" id="14_r3"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/light1.png" id="15_r3"]
```

### 3) 提亮既有背景（逐一替換 modulate 那一行）
- `SkyBackdrop`：把 `modulate = Color(0.1, 0.18, 0.16, 0.5)` 改成 `modulate = Color(0.22, 0.34, 0.3, 0.85)`
- `RuinedWallA`：把 `modulate = Color(0.35, 0.45, 0.42, 0.28)` 改成 `modulate = Color(0.4, 0.52, 0.48, 0.5)`
- `RuinedWindow`：把 `modulate = Color(0.45, 0.55, 0.65, 0.35)` 改成 `modulate = Color(0.5, 0.62, 0.78, 0.6)`

### 4) 新增裝飾節點
找到這一行：
```
[node name="PortalFromRoom2" parent="." instance=ExtResource("1_r3")]
```
在它**正上方**插入以下整段（全部負 z_index，不會擋玩家）：
```
[node name="HallColumnLeft" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.4, 0.5, 0.45, 0.7)
position = Vector2(150, 450)
scale = Vector2(0.95, 2.0)
texture = ExtResource("13_r3")

[node name="HallColumnRight" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.4, 0.5, 0.45, 0.7)
position = Vector2(2420, 450)
scale = Vector2(0.95, 2.0)
texture = ExtResource("14_r3")

[node name="ThroneColumn" type="Sprite2D" parent="."]
z_index = -6
modulate = Color(0.34, 0.44, 0.4, 0.55)
position = Vector2(1880, 430)
scale = Vector2(1.1, 2.2)
texture = ExtResource("14_r3")

[node name="TorchLeft" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.85, 0.78, 0.55, 0.7)
position = Vector2(620, 380)
scale = Vector2(0.5, 0.5)
texture = ExtResource("15_r3")

[node name="TorchThrone" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.9, 0.82, 0.58, 0.75)
position = Vector2(1880, 300)
scale = Vector2(0.6, 0.6)
texture = ExtResource("15_r3")
```

## 驗收條件
1. headless 跑 `res://src/world/Game.tscn` 無 `SCRIPT ERROR` / `Parse Error`（忽略關機雜訊）。
2. 遊戲中 F10 → 3 跳到 Room3，截圖可見：背景比之前亮、左右有柱、王座側有大柱、有暖色燈光點 → 像個大廳，不再是黑底色塊。
3. Boss、敵人、地板、閘門、傳送門位置與行為**完全不變**（沒動到禁改節點）。
4. 截圖存到 `.scratch/spec001_room3.png` 一併回報。

## 回報
依 `README_GEMINI.md` 第 6 節格式回報。
</content>
