# SPEC-004 — Room6 美術補強（祕藏石室）

**先讀 `docs/specs/README_GEMINI.md`。只改 `src/world/Room6.tscn`。**

## 目標
Room6 是隱藏寶室，目前只有 1 個背景光暈、太空。加入柱與暖色寶藏光，讓它像「值得爬上來的祕藏石室」。

## 禁改範圍
- 不要動 `StaticEnvironment`（Floor/Ceiling/LeftWall/RightWall）、`PortalFromRoom1`、`SecretCache`、`HiddenBench`、`SpawnPoint`。
- 只准：改 `load_steps`、新增 2 個 texture `ext_resource`、改 `BackGlow` 的 `modulate`、新增裝飾 sprite 節點。

## 步驟
### 1) load_steps
第 1 行 `load_steps=8` → 改成 `load_steps=10`。

### 2) 新增 ext_resource
找到：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/light1.png" id="5_r6"]
```
在它正下方加：
```
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column1.png" id="6_r6"]
[ext_resource type="Texture2D" path="res://assets/sprites/hollow_imitation/decoration/column2.png" id="7_r6"]
```

### 3) 提亮中央光暈（暖金寶藏感）
- `BackGlow`：`modulate = Color(0.6, 0.8, 1, 0.3)` → `modulate = Color(0.95, 0.82, 0.5, 0.45)`

### 4) 新增裝飾節點
找到：
```
[node name="PortalFromRoom1" parent="." instance=ExtResource("2_r6")]
```
在它正上方插入：
```
[node name="CacheColumnLeft" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.42, 0.46, 0.4, 0.6)
position = Vector2(120, 470)
scale = Vector2(0.9, 1.8)
texture = ExtResource("6_r6")

[node name="CacheColumnRight" type="Sprite2D" parent="."]
z_index = -5
modulate = Color(0.42, 0.46, 0.4, 0.6)
position = Vector2(1160, 470)
scale = Vector2(0.9, 1.8)
texture = ExtResource("7_r6")

[node name="CacheGlow" type="Sprite2D" parent="."]
z_index = -4
modulate = Color(1.0, 0.85, 0.45, 0.6)
position = Vector2(940, 560)
scale = Vector2(0.6, 0.6)
texture = ExtResource("5_r6")
```

## 驗收條件
1. headless 無 `SCRIPT ERROR`/`Parse Error`。
2. F10 → 6 跳到 Room6，截圖：暖金光暈、左右兩柱、寶物(SecretCache)附近有金光；長椅與寶物位置不變。
3. 截圖存 `.scratch/spec004_room6.png`。

## 回報
依 `README_GEMINI.md` 第 6 節格式。
</content>
