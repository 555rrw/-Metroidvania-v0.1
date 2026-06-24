# SPEC-003 — Room5 美術提升（捷徑試煉道）

**先讀 `docs/specs/README_GEMINI.md`。只改 `src/world/Room5.tscn`。**

## 目標
提亮 Room5 背景、加入裝飾，讓「捷徑試煉道」有幽徑試煉氛圍。

## 禁改範圍（重要）
- **不要刪或改** `DanielDFYLevel2VisualCopy`、`DanielDFYLevel2GameplayCopy`（第28行 metadata 也不要動）。
- 不要動 `StaticEnvironment`、所有 `Portal*`/`ShortcutReturn`、`SpellGate`/`SpellShortcutWall`/`ShortcutSeal`、
  `*Trap*`、`SawTrap*`、`AcidPool`、`MovingPlatform`、`UnstablePlatform*`、`ShortcutSwitch`/`ShortcutDoor`、`ShortcutGunner`、`SecretPickup`、`SpawnPoint`。
- 只准：改 `load_steps`、新增 2 個 texture `ext_resource`、改 `SkyBackdrop` 的 `modulate`、新增裝飾 sprite 節點。

## 步驟
### 1) load_steps
第 1 行 `load_steps=20` → 改成 `load_steps=22`。

### 2) 新增 ext_resource
找到：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/platform/platform1.png" id="6_r5"]
```
在它正下方加：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column1.png" id="18_r5"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/light1.png" id="19_r5"]
```

### 3) 提亮背景
- `SkyBackdrop`：`modulate = Color(0.12, 0.23, 0.16, 0.45)` → `modulate = Color(0.22, 0.36, 0.3, 0.82)`

### 4) 新增裝飾節點
找到：
```
[node name="PortalFromRoom4" parent="." instance=ExtResource("1_r5")]
```
在它正上方插入：
```
[node name="TrialColumnLeft" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.36, 0.5, 0.4, 0.62)
position = Vector2(150, 450)
scale = Vector2(0.95, 2.0)
texture = ExtResource("18_r5")

[node name="TrialColumnRight" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.36, 0.5, 0.4, 0.62)
position = Vector2(2420, 450)
scale = Vector2(0.95, 2.0)
texture = ExtResource("18_r5")

[node name="TrialGlowA" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.6, 0.92, 0.68, 0.5)
position = Vector2(700, 400)
scale = Vector2(0.7, 0.7)
texture = ExtResource("19_r5")

[node name="TrialGlowB" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(0.6, 0.92, 0.68, 0.5)
position = Vector2(1900, 380)
scale = Vector2(0.7, 0.7)
texture = ExtResource("19_r5")
```

## 驗收條件
1. headless 無 `SCRIPT ERROR`/`Parse Error`。
2. F10 → 5 跳到 Room5，截圖：背景變亮、左右有柱、有綠色幽光；DanielDFY 疊層仍在；陷阱/閘門位置不變。
3. 截圖存 `.scratch/spec003_room5.png`。

## 回報
依 `README_GEMINI.md` 第 6 節格式。
</content>
