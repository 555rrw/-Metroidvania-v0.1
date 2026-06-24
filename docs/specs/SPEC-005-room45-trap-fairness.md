# SPEC-005 — Room4 / Room5 落石公平性修正

**先讀 `docs/specs/README_GEMINI.md`。改兩個檔：`src/world/Room4.tscn`、`src/world/Room5.tscn`。**

## 問題
兩房的開關正上方就是落石陷阱，玩家踩開關＝落石砸頭，不公平。修法：把落石的 X 座標移到開關與門之間的前進路線上（玩家踩完開關往右走時才落下，看得到、躲得掉）。**只改落石的 position，其他全部不動。**

## 禁改範圍
- 只改下列兩個 `FallingTrap` 節點的 `position` 那一行。其餘節點（開關、門、gunner、平台、傳送門、DanielDFY 疊層…）一律不動。
- 不要改 `load_steps`、不要新增/刪除節點、不要改 `trap_path` 連結。

## 步驟
### Room4（`src/world/Room4.tscn`）
找到：
```
[node name="SanctumFallingTrap" parent="." instance=ExtResource("7_r4")]
position = Vector2(1880, 150)
```
把 position 改成：
```
position = Vector2(2030, 150)
```
（開關在 1840、門在 2110；移到 2030＝兩者之間的路線上。）

### Room5（`src/world/Room5.tscn`）
找到：
```
[node name="ShortcutFallingTrap" parent="." instance=ExtResource("13_r5")]
position = Vector2(1840, 140)
```
把 position 改成：
```
position = Vector2(1990, 140)
```
（開關在 1810、門在 2070；移到 1990＝兩者之間的路線上。）

## 驗收條件
1. headless 無 `SCRIPT ERROR`/`Parse Error`。
2. 兩房只有那兩行 position 改變（用 `git diff` 確認 diff 僅 2 行）。
3. F10 → 4 / F10 → 5 進房，落石不再位於開關正上方。

## 備註
Room2 的同類問題已由架構師修正（FallingTrap 已移到 2300,150），本規格不含 Room2。

## 回報
依 `README_GEMINI.md` 第 6 節格式。
</content>
