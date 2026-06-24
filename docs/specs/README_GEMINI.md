# 實作者操作手冊（Gemini 3.5 Flash 必讀）

你是**實作者**。架構師會給你一份 `SPEC-NNN-*.md`。你的工作：**只照那份規格改，不要自己做設計決策、不要順手改別的東西**。改完跑自我驗證並回報。

---

## 0. 環境
- 引擎：Godot 4.7。專案根目錄含中文路徑：`F:\神骸世界 Metroidvania 開發藍圖 v0.2`。
- Godot 執行檔：`C:\Users\ss093\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`
  （帶 log 的版本：同資料夾的 `..._console.exe`）。
- 主場景：`res://src/ui/MainMenu.tscn`；遊戲場景：`res://src/world/Game.tscn`。

## 1. 鐵則（違反就會弄壞專案）
1. **`.tscn` / `.tres` / `MapData.txt` 不能加 `#` 註解** — 會解析失敗。註解只能寫在 `.gd`（GDScript 用 `#`、文件註解用 `##`）。
2. **`.tscn` 加了 `ext_resource` 或 `sub_resource` 就要改檔頭的 `load_steps`**（數字 = ext + sub 資源總數，寧可多不可少）。
3. **不要改帶 `GPT5.5_LOCK` / `CLAUDE4.8_LOCK` 的程式行為**，也不要動 `docs/*_locked_systems.md` 列的系統，除非 SPEC 明寫要改。
4. **只動 SPEC 指定的檔案與節點**。不要重排、不要重新命名、不要「順便優化」。
5. 不確定就**停下回報**，不要猜。

## 2. 專案慣例（照抄即可）
- **碰撞層**：地板/牆/天花板/平台的 `StaticBody2D` 用 `collision_layer = 5`、`collision_mask = 0`。
- **單向平台**（可從下方跳穿、站上方）：其 `CollisionShape2D` 加 `one_way_collision = true`。
- **玩家跳躍高度約 93px**：要讓玩家跳得上去，平台**垂直間距 ≤ 約 85px**。間距太大他跳不上去。
- **房間結構**：每房有 `RoomInstance` 節點(掛 `addons/MetroidvaniaSystem/Scripts/RoomInstance.gd`)、`SpawnPoint`(Marker2D)、`Background`(ColorRect，決定房間大小/相機邊界)、`StaticEnvironment`(地板牆)。
- **傳送門**（房間互通）：用 `src/objects/Portal.tscn`，設 `target_room`(目標 .tscn) 與 `target_portal_name`(目標房裡同名 Portal)。兩房各放一個同名規則的 Portal 形成雙向。
- **進場安全**：`SpawnPoint` 與玩家進場點附近不要有敵人/陷阱/地刺（會一進場就被打）。
- **中文字**：Godot 內建字型沒有中文，純 `Label` 顯示中文會變空白。需顯示中文時用 `HUD.gd` 既有的 `_make_cjk_font()`（SystemFont）。

## 3. MapData.txt 格式（地圖）
每個 cell 兩行：
```
[x,y,z]
right,bottom,left,top|<空>|<index>|res://src/world/RoomN.tscn
```
- 邊界四值順序 = **右,下,左,上**。`-1`=通道(開)、`0`=牆、正數=特殊邊框。
- 同一房跨多 cell 時，相鄰邊用 `-1` 互通。
- 往上開分支：上格 `bottom=-1`、下格 `top=-1`。

## 4. 美術修法（P0 房間用，照 Room2 範本）
讓裸色塊房變得有氛圍，標準做法（全部放負 `z_index`，不擋玩家）：
1. 背景 sprite 提亮：`modulate` 的 RGB 拉高、alpha 拉到 0.8 左右（別留太暗看不見）。
2. 加裝飾 sprite（負 z_index，例 -5）：柱 `decoration/column1.png`、燈 `decoration/light1.png`、結構 `framework/floor1.png`、牆 `framework/ruins_mid_walls_0002_a.png`。
3. 可用素材清單見 `docs/asset_usage_audit.md`；**先用既有素材，不要憑空造圖**。
4. 不要用 sprite 蓋在地板碰撞上方造成擋住玩家的 z 衝突 —— 裝飾一律負 z。

## 5. 自我驗證（改完一定要做）
A. **語法/載入檢查**（headless）：
```
"<console.exe>" --headless --path "<專案根>" "res://src/world/Game.tscn"
```
跑約 8 秒。**只在意 `SCRIPT ERROR` 與 `Parse Error`**。以下是關機雜訊，**不是錯誤、要忽略**：
`Unreferenced static string`、`RID allocations ... leaked at exit`、`Pages in use`、`NavMesh ... leaked`。

B. **實機/截圖檢查**（要看畫面時）：用 `tools/capture-godot-window.ps1` 或直接開遊戲。
   - 用**開發者傳送**跳到指定房：遊戲中按 `F10` 開 DEV 面板，再按 `1`~`6` 跳 Room1~Room6。
   - 注意：若 `user://hollow_knight_save.sav` 存在，直接開 `Game.tscn` 會從存檔房開始；要從頭測先刪存檔
     （`%APPDATA%\Godot\app_userdata\Hollow Knight Clone\hollow_knight_save.sav`）。
   - 測完**確認只有一個 Godot 視窗**，別被殘留舊視窗的截圖誤導。

## 6. 回報格式（每個 SPEC 做完回這個）
```
SPEC-NNN 結果
- 改了哪些檔/節點：…
- headless：無 SCRIPT ERROR（或貼出錯誤）
- 驗收條件逐條：✅/❌ + 證據（截圖檔名）
- 有無動到禁改範圍：無
- 不確定/卡住的點：…
```
</content>
