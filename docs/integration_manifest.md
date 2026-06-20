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
`SourceArchive.gd` scans those folders at startup and indexes every non-`.git` file for runtime provenance. The source count is kept off the shipped HUD so the playable slice presents as a game, not an integration debug screen.

## Playable v1 Feature Set

- Five MetSys rooms: Crossroads, Greenpath, False Knight chamber, Spirit Sanctum, shortcut cache.
- Player movement: run, tuned acceleration/deceleration, coyote jump, jump buffer, variable jump height, dash unlock, double jump unlock, wall slide/jump, look up/down camera.
- Combat: directional nail hitboxes, pogo bounce, hit pause, recoil, Soul gain, Focus heal, Vengeful Spirit spell, hurt/invincibility, save respawn.
- Enemies: Crawlid patrol, Vengefly chase/hover, False Knight phase boss with leap/slam/shockwave/stagger/death reward.
- Objects: save point, room portals, spikes, moving platform, ability gates, spell/ability unlocks, secret Soul pickup.
- UI: health masks, Soul meter, unlock popup, MetSys minimap.

## Hollow Knight Gap Closed in This Slice

- Progression loop now has ability gate -> boss reward -> spell shrine -> secret shortcut return.
- Combat now has readable attack directions, Soul spend/gain, hit feedback, and a boss pattern closer to a Hollow Knight-style early fight.
- Presentation remains asset-mix prototype quality, but formal debug/source labels are hidden from the shipped HUD.
