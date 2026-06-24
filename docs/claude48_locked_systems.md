# Claude 4.8 Locked Systems

Date: 2026-06-24

Same rule as `gpt55_locked_systems.md`: these parts are verified working. Do not delete, rename,
or rewrite them without preserving the described behavior and re-running the listed checks.
Inline code carries `CLAUDE4.8_LOCK` comments; scene/config changes (which cannot hold comments)
are registered only here.

## Locked Runtime Logic

| Area | Files | Behavior to preserve | Required checks before changing |
| --- | --- | --- | --- |
| Room1 fair opening | `src/world/Room1.tscn` | Spawn(600,592) kept clear; single Crawlid intro at (840), two MantisWarrior spears flank an arena at (980/1150) before the exit. Preserves the gpt55 flanking-encounter intent while removing the spawn pile-up. | Room1 screenshot; player not hit within ~1s of spawn. |
| Area-title banner | `src/ui/HUD.gd` (`_setup_area_title`, `show_area_title`, `_make_cjk_font`), `src/world/Game.gd` (`AREA_TITLES`, `_show_area_title_for_current_room`) | Area name fades in on room *scene* change (not same-room respawn / same-scene scroll). CJK renders via SystemFont. | Headless run (no SCRIPT ERROR); screenshot shows title; `[AREATITLE]` mapping resolves. |
| Full-screen map screen | `src/ui/HUD.gd` (`_setup_map_overlay`, `_toggle_map`, `_set_map_open`, `_unhandled_input` map branch), `project.godot` (`map` action = M) | M toggles map; pauses game; mutually exclusive with pause menu; MetSys Minimap `track_position=true area(11,7) display_player_location=true`; only explored cells shown. | Headless run; screenshot with real M keypress shows map + player marker. |
| On-screen minimap enabled | `src/ui/HUD.tscn` (`Minimap.visible = true`) | The corner minimap is shown during play (was `visible=false`). | Screenshot shows minimap top-right. |
| Room2 art/logic reference treatment | `src/world/Room2.tscn` | Reference example the P0 specs mirror: backgrounds brightened (SkyBackdrop/MountainBackdrop/RuinWallTexture modulate), negative-z decoration sprites (BackLedge/ColumnLeft/ColumnRight/LampGlowLeft/LampGlowRight), and the unfair FallingTrap moved off the switch (now 2300,150). Keep these when editing Room2. | Headless run clean. |
| Vertical map branch (Room6) | `src/world/Room6.tscn` (new), `src/world/Room1.tscn` (ClimbPlat1-3/ClimbLedge + `PortalToRoom6`), `src/world/MapData.txt` (cell `[0,-1,0]`=Room6, Room1 `[0,0,0]` top opened to -1), `src/world/Game.gd` (Room6 in `AREA_TITLES`/`DEV_ROOMS`, KEY_6 dev warp) | Room6 ("祕藏石室") is a hidden alcove above Room1 reached by a left-side platform climb + `PortalToRoom6`; holds a SecretCache + bench. Makes the map genuinely 2D (branch up). Bidirectional portal pattern: Room1.PortalToRoom6 <-> Room6.PortalFromRoom1. | Headless run; dev-warp (F10,6) loads Room6 with no MetSys bounce; minimap shows Room6 cell above the Room1 row. |

## Marker Rule

`CLAUDE4.8_LOCK` comments in code mean: do not delete, rename, or rewrite that logic without
preserving behavior and updating this file with new evidence. Scene/config items above have no
inline marker because `.tscn`/`project.godot` do not support comments.
