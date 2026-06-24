# 神骸世界 — Master Plan (架構師路線圖)

Maintained by the architect (Claude 4.8). Implementation is delegated to a cheaper model
(Gemini 3.5 Flash) via atomic specs in `docs/specs/`. The architect writes specs + reviews;
the implementer only applies specs exactly.

> 目標：在不抄襲正版受著作權的素材/劇情/音樂的前提下，把**遊戲機制與手感**做到接近
> Hollow Knight 類銀河城的水準。所有美術沿用 `cloned_repos/` 與 `assets/` 既有素材。

---

## 1. 現況（2026-06-24）

可運作的 Godot 4.7 專案，主場景 `res://src/ui/MainMenu.tscn`。已具備：

- **玩家手感**（完成度高）：跑/土狼時間/跳躍緩衝/可變跳/衝刺/二段跳/滑牆+蹬牆跳/下劈pogo/聚集回血/復仇之魂法術 — `src/player/Player.gd`
- **戰鬥**：方向性釘擊、命中停頓、後座力、Soul 增減、受擊無敵 — `Player.gd` + `src/combat/HitInfo.gd`
- **世界**：6 房（Room1–6）+ MetSys 地圖、存讀檔、長椅、傳送門、開發者傳送(F10+數字) — `src/world/Game.gd`
- **地圖**：小地圖 + 全螢幕地圖(M鍵) + 一條垂直分支(Room6) — `src/ui/HUD.gd`, `src/world/MapData.txt`
- **Boss**：False Knight（分階段）— `src/enemies/FalseKnight.gd`
- **敵人**：Crawlid / Vengefly / Gunner / MantisWarrior
- **物件**：spikes/saw/落石/移動平台/崩塌平台/開關門/能力閘/能力解鎖/祕密拾取/可破壞牆

### 品質落差（要修的）
- **美術不均**：Room1 有 33 個裝飾 sprite；Room2–5 只有 2–7 個、地板/牆是裸 ColorRect 色塊。Room2 已開始示範修法。
- **關卡邏輯**：後段房有不公平陷阱（如開關正上方落石）、流程擁擠、多餘閘門。
- **缺核心養成系統**：無貨幣(Geo)、無護符(charm)、無升級收集物（加血/加魂/骨釘）、法術只有 1 招。
- **缺敘事/NPC/第二隻 Boss**。

---

## 2. 程式碼分區（指令時引用這些）

每個 `src/*.gd` 檔頭都有 `## 用途` 一行，內部用 `# -- Section --` / `# ---- subsection ----` 分區。
下指令時請用「檔案 + 區段名」定位，例如「在 `Player.gd` 的 `# ---- Soul & Spell Mechanics ----` 區段新增…」。

| 區域 | 檔案 | 負責 |
| --- | --- | --- |
| 玩家 | `src/player/*.gd` | 移動/戰鬥/法術/攝影機 |
| 敵人 | `src/enemies/*.gd` | AI/Boss/投射物 |
| 物件 | `src/objects/*.gd` | 陷阱/平台/門/閘/拾取 |
| 世界 | `src/world/Game.gd`, `Room*.tscn`, `MapData.txt` | 房間/轉場/地圖/存檔 |
| UI | `src/ui/*.gd` | HUD/選單/地圖/暫停 |
| 戰鬥資料 | `src/combat/HitInfo.gd` | 命中資訊 |

**鎖定系統**：帶 `GPT5.5_LOCK` 或 `CLAUDE4.8_LOCK` 註解、以及 `docs/*_locked_systems.md` 列出的行為，
非經架構師指示不得改寫（改寫須保留行為並更新該文件）。Claude 4.8 權限高於 gpt55。

---

## 3. 路線圖（Phase）

### P0 — 把現有 6 房做到「不糟」（進行中，最高優先）
0.1 美術：Room3/4/5（+Room6）比照 Room2 修法 — 提亮背景、加柱/燈/結構裝飾、去除裸色塊觀感。
0.2 邏輯：逐房修不公平陷阱、釐清前進路線、移除多餘閘門、確保進場安全。
- 觸及：`Room2–6.tscn`。規格：`SPEC-001`～。

### P1 — 核心養成系統（最像 HK 的深度）
1.1 **Geo 貨幣**：敵人死亡掉 Geo、地上可撿、HUD 計數、存檔。
1.2 **升級收集物**：面具碎片(集滿+1血上限)、魂器(集滿+魂上限)、骨釘強化(+傷害階級)。
1.3 **商店**：一個 NPC/商人房，用 Geo 購買升級/護符。
1.4 **護符系統**：護符拾取、凹槽上限、裝備面板、被動效果（如回魂加速、釘擊加長、落地震波）。
1.5 **法術擴充**：新增 1–2 招（範圍嚎魂式、向下俯衝式），耗魂、有冷卻。
- 觸及：新增 `src/systems/`（Geo/Charm 管理）、`src/ui/`（商店/護符面板）、`Player.gd`、`Game.gd` 存檔。

### P2 — 世界與內容
2.1 地圖再分支（更多上下/側向房間、fast-travel 長椅）。
2.2 新增 2–3 種敵人 + 第二隻 Boss。
2.3 NPC/對話/告示牌（自製劇情，非抄正版）。

### P3 — 表現力打磨
音效、粒子、轉場淡入淡出、視差背景、打擊感(screen shake/hitstop 調校)、UI 動態。

---

## 4. 委派與審核流程

1. 架構師（Claude 4.8）把一個 Phase 拆成多個**原子規格** `docs/specs/SPEC-NNN-*.md`。
2. 實作者（Gemini 3.5 Flash）讀 `docs/specs/README_GEMINI.md` + 單一 SPEC，**只照規格改**，不做設計決策。
3. 實作者跑自我驗證（headless + 截圖），回報結果。
4. 架構師審核：headless 無 SCRIPT ERROR、行為符合驗收條件、未動鎖定系統 → 通過/退回。

規格務必：**單檔單變更、給出精確路徑/錨點/可貼上的程式或節點區塊、列出格式規則、驗收條件、禁改範圍**。
</content>
