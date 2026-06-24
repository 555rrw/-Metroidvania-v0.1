# SPEC-002 — Room4 美術提升（魂之聖所）

**先讀 `docs/specs/README_GEMINI.md`。只改 `src/world/Room4.tscn`。**

## 目標
提亮 Room4 背景、加入裝飾，讓「魂之聖所」有神聖幽光氛圍（冷藍綠調）。

## 禁改範圍（重要）
- **不要刪或改** `DanielDFYLevel2VisualCopy`、`DanielDFYLevel2GameplayCopy`（gpt55 鎖定，第30行 metadata 也不要動）。
- 不要動 `StaticEnvironment`、所有 `Portal*`、`*Switch`/`*Door`/`*Gate`、`*Trap`、`AcidPool`、
  `SpiritUpgrade`、`SpiritPracticeWall`、`MovingPlatform`、`UnstablePlatform*`、`SanctumGunner`、`SanctumRelic`、`SpawnPoint`。
- 只准：改 `load_steps`、新增 2 個 texture `ext_resource`、改 `SkyBackdrop`/`ChainA` 的 `modulate`、新增裝飾 sprite 節點。

## 步驟
### 1) load_steps
第 1 行 `load_steps=22` → 改成 `load_steps=24`。

### 2) 新增 ext_resource
找到：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/chain_01.png" id="17_r4"]
```
在它正下方加：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column1.png" id="20_r4"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/light1.png" id="21_r4"]
```

### 3) 提亮既有背景
- `SkyBackdrop`：`modulate = Color(0.12, 0.23, 0.16, 0.45)` → `modulate = Color(0.2, 0.34, 0.38, 0.82)`
- `ChainA`：`modulate = Color(0.5, 0.55, 0.65, 0.4)` → `modulate = Color(0.6, 0.7, 0.85, 0.6)`

### 4) 新增裝飾節點
找到：
```
[node name="PortalFromRoom3" parent="." instance=ExtResource("1_r4")]
```
在它正上方插入：
```
[node name="SanctumColumnLeft" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.35, 0.45, 0.55, 0.65)
position = Vector2(150, 450)
scale = Vector2(0.95, 2.1)
texture = ExtResource("20_r4")

[node name="SanctumColumnRight" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.35, 0.45, 0.55, 0.65)
position = Vector2(2420, 450)
scale = Vector2(0.95, 2.1)
texture = ExtResource("20_r4")

[node name="SpiritGlowA" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.5, 0.78, 0.9, 0.55)
position = Vector2(520, 430)
scale = Vector2(0.7, 0.7)
texture = ExtResource("21_r4")

[node name="SpiritGlowB" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.5, 0.78, 0.9, 0.5)
position = Vector2(1900, 380)
scale = Vector2(0.8, 0.8)
texture = ExtResource("21_r4")
```

## 驗收條件
1. headless 跑 `res://src/world/Game.tscn` 無 `SCRIPT ERROR`/`Parse Error`。
2. F10 → 4 跳到 Room4，截圖：背景變亮、左右有柱、有藍色聖光點；DanielDFY 疊層仍在。
3. 禁改節點完全不變。截圖存 `.scratch/spec002_room4.png`。

## 回報
依 `README_GEMINI.md` 第 6 節格式。
</content>
