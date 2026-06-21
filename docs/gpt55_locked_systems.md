# GPT5.5 Locked Systems

Date: 2026-06-21

These parts are verified working. Future AI agents should not rewrite them unless the replacement keeps the same behavior and reruns the listed checks.

## Locked Runtime Logic

| Area | Files | Lock reason | Required checks before changing |
| --- | --- | --- | --- |
| Attack input and nail hitbox | `project.godot`, `src/player/Player.gd`, `src/player/Player.tscn`, `src/tests/AttackInputRunner.tscn` | `attack` action reaches `_perform_attack()`, enables nail collision, shows slash, preserves side/up/down hitboxes. | `src/tests/AttackInputRunner.tscn`, `DanielFeatureRunner`, screenshot capture. |
| Player combat silhouette | `src/player/Player.gd` | Side slash no longer covers the player mask/body in Room1 combat screenshot. | Screenshot capture. |
| Room1 flanking encounter | `src/world/Room1.tscn`, `src/enemies/MantisWarrior.gd`, `src/enemies/MantisWarrior.tscn` | Left/right spear enemies face player, keep HK-like flanking combat read. | `RouteRunner`, screenshot capture. |
| Room routing and MetSys integration | `src/world/Game.gd`, `src/world/Room*.tscn`, `addons/MetroidvaniaSystem/` | Rooms 1-5 load through current MetSys flow. | `RouteRunner`. |
| DanielDFY parity systems | `src/objects/*.gd`, `src/enemies/Gunner*.gd`, `src/objects/*Trap*.gd` | Switch, falling trap, unstable platform, gunner projectile verified. | `DanielFeatureRunner`. |

## Marker Rule

`GPT5.5_LOCK` comments in code mean: do not delete, rename, or rewrite that logic without preserving behavior and updating this file with new evidence.
