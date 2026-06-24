# SPEC-103 (草稿) — 護符系統 架構與分階段

> 這是**架構師草稿**，不是給 Gemini 的最終可執行規格。護符系統較複雜，先定架構，
> 待 SPEC-101(Geo)/SPEC-102(升級) 驗收後，再由架構師拆成 103a/103b/103c 的逐步可貼程式規格。

## 設計目標（自製，不抄正版受著作權內容）
- 拾取護符 → 在護符面板裝備 → 受凹槽(notch)上限限制 → 提供被動效果。
- 是最招牌的 build 養成。先做 3~4 個簡單被動即可。

## 資料模型
- 護符以**資源**定義：新增 `src/systems/Charm.gd`（`extends Resource`，`class_name Charm`）
  欄位：`id: StringName`、`display_name: String`、`notch_cost: int`、`description: String`、`icon: Texture2D`。
- 用 `.tres` 建幾個護符實例放 `assets/charms/`（或先在程式內用字典定義，避免 Gemini 建 .tres 出錯 → **建議先字典版**）。

## 狀態與持久化
- 新增單例/管理：`src/systems/CharmManager.gd`（可做成 autoload，或掛在 `Game`）。
  - `owned: Array[StringName]`（已擁有）
  - `equipped: Array[StringName]`（已裝備）
  - `notch_limit: int = 3`、`func used_notches() -> int`
  - `func can_equip(id) -> bool`、`equip(id)`、`unequip(id)`、`has_equipped(id) -> bool`
- 存讀檔：在 `Game.save_game`/載入區段，存 `owned`、`equipped`、`notch_limit`
  （比照現有 `events`/`abilities` 的 set_value/get_value 寫法）。

## 效果掛鉤（在 Player.gd 查詢 CharmManager）
先做這幾個低風險被動，效果都在 `Player.gd` 既有區段查 `has_equipped`：
| 護符 | notch | 效果 | 掛鉤位置（Player.gd 區段） |
| --- | --- | --- | --- |
| 迅魂 | 1 | 聚集回血更快（focus_time × 0.7） | `_handle_focus` |
| 長釘 | 2 | 釘擊範圍加長（_configure_nail_hitbox 尺寸 ×1.2） | `_configure_nail_hitbox` |
| 厚甲 | 2 | 受擊無敵時間加長（invincible 1.15→1.6） | `take_damage` |
| 貪魂 | 1 | 每次命中多 +Soul | `_on_nail_area_body_entered` |

## UI（護符面板）
- 比照 `HUD.gd` 既有 overlay（暫停選單 / 全螢幕地圖）的做法，做一個 `charm_overlay`：
  - 新增輸入動作（例如 `charm` 綁 `I` 或 `C`… 注意 `C` 已是 dash，避開；建議 `I`）。
  - 顯示：已擁有護符清單、凹槽用量(used/limit)、點選裝備/卸下。
  - 開啟時 `paused=true`，與暫停/地圖互斥（比照現有互斥邏輯）。

## 拆分計畫（之後各自成 Gemini 規格）
- **103a**：`Charm.gd` + `CharmManager.gd`（字典版護符定義）+ Game 存讀檔。純資料，無 UI。可先用程式直接 `equip` 測試效果。
- **103b**：Player.gd 4 個效果掛鉤（每個都查 `has_equipped`，給精確錨點與貼上程式）。
- **103c**：HUD 護符面板 overlay + 輸入動作 + 互斥邏輯。
- **103d**：把護符做成可拾取（沿用 SPEC-102 的 pickup 模式，撿到 → `CharmManager.owned.append`）。

## 待架構師決定
- 護符定義先用「程式字典」還是「.tres 資源」？（建議字典，降低 Gemini 建檔風險）
- notch 上限怎麼成長？（先固定 3，之後接 P1 升級物）
- 護符面板放暫停選單內，還是獨立鍵？（建議獨立鍵 `I`）

> 結論：先讓 Gemini 跑完 SPEC-101/102 驗收，架構師再產出 103a 起的逐步規格。
</content>
