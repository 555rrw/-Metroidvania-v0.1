# Hollow Knight Clone v1 Integration Manifest

Godot version: 4.7.
Main scene: `res://src/world/Game.tscn`.

## Source Repositories

| Source | Commit | Runtime use |
| --- | --- | --- |
| DanielDFY/Hollow-Knight-Imitation | `c443c6262ab85d007c8ed6f3abb42a8b077df007` | Player frame sets, UI/title watermark, ruin/floor textures, trap and room interaction behavior ported into GDScript. |
| KoBeWi/Metroidvania-System | `d9e456dc535e5e0f9d7831974353e976355e505e` | Full `addons/MetroidvaniaSystem`, autoload, minimap, save data, room map data, `RoomInstance` integration. |
| gdquest-demos/godot-platformer-2d | `0ea6cb6056dceeba4b1eeca73bddd9e037e0a7ef` | Background art, hook/checkpoint props, moving platform waypoint behavior pattern, source archive indexing. |
| Antonius-k/CloneProject_HollowKnight | `37006ddcd7377dff5c31ae0034e7a2d7fcb76368` | Enemy/boss sprites, False Knight audio, boss encounter behavior and reward loop. |
| ChrisMGeo/GodotHollowKnightController | `0f076abfc008ea99b68dd08f9b40c5b08cd1427e` | Controller movement ideas ported into `Player.gd`; warrior sheet appears as controller echo in boss room; full repo indexed. |

## Full Source Retention

The five upstream repositories are retained as git submodules under `cloned_repos/`.
`SourceArchive.gd` scans those folders at startup and indexes every non-`.git` file. The HUD displays the indexed repo/file count so the playable project exposes source-corpus usage in runtime.

## Playable v1 Feature Set

- Three MetSys rooms: Crossroads, Greenpath, boss chamber.
- Player movement: run, coyote jump, jump buffer, variable jump height, dash unlock, double jump unlock, wall slide/jump, nail attack, pogo bounce, hurt/invincibility, save respawn.
- Enemies: Crawlid patrol, Vengefly chase/hover, False Knight boss with leap/slam/stagger/death reward.
- Objects: save point, room portals, spikes, moving platform, ability unlocks.
- UI: health masks, ability readout, unlock popup, MetSys minimap, source archive readout.
