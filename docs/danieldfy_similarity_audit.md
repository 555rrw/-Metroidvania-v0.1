# DanielDFY Hollow-Knight-Imitation Similarity Audit

Date: 2026-06-20
Reference: `DanielDFY/Hollow-Knight-Imitation` at `c443c6262ab85d007c8ed6f3abb42a8b077df007`.

## Verdict

Current Godot build clears the first-version threshold for DanielDFY-style feature parity: 84 / 100.

This is not a pixel-perfect Unity scene recreation. The score measures playable systems, screenshot coverage, script-behavior coverage, and direct resource use from the DanielDFY project.

## Score

| Area | Weight | Current | Evidence |
| --- | ---: | ---: | --- |
| Menu, pause, HUD flow | 15 | 13 | `MainMenu.tscn`, `HUD.tscn` pause overlay, health masks, Start/Load/Quit, Continue/Menu/Quit. |
| Player controller parity | 20 | 17 | Run, jump, double jump, wall slide/jump, dash, up/side/down nail, recoil, hurt, invulnerability, death reload. |
| Enemy parity | 15 | 13 | Patrol/chase enemy, flying chase enemy, gunner enemy, projectile spawn, contact damage, death handling. |
| Trap and switch parity | 20 | 18 | Moving platform, unstable platform, falling trap, saw/spikes, projectile destruction, attackable switch, door opening, event persistence. |
| Scene/screenshot coverage | 15 | 12 | Menu, Spawn-like Room1, enemy chase, climb/wall movement, trigger trap, pause, attack, enemy attacking, moving platform all represented. |
| Direct DanielDFY resource use | 15 | 11 | Menu/title/pointer/fleur, spawn/menu backgrounds, door/entry, platform/unstable platform, trigger atlas, saw/spike, enemy sprites imported and used. |

Total: 84 / 100.

## Script Behavior Mapping

| DanielDFY script | Godot implementation |
| --- | --- |
| `PlayerController.cs` | `src/player/Player.gd` |
| `GlobalController.cs` | `src/world/Game.gd` |
| `Menu.cs` | `src/ui/MainMenu.gd` |
| `HUD.cs`, `HealthDisplay.cs` | `src/ui/HUD.gd` |
| `EnemyController.cs` | `src/enemies/Enemy.gd` |
| `PatrolController.cs` | `src/enemies/Crawlid.gd` plus base enemy behavior |
| `GunnerController.cs` | `src/enemies/Gunner.gd` |
| `Projectile.cs` | `src/enemies/GunnerProjectile.gd` |
| `Switch.cs` | `src/objects/SwitchTrigger.gd` |
| `Obstacle.cs` | `src/objects/TriggerDoor.gd` |
| `Trap.cs` | Trigger methods on trap objects |
| `UnstablePlatform.cs` | `src/objects/UnstablePlatform.gd` |
| `FallingTrap.cs` | `src/objects/FallingTrap.gd` |
| `MovingTrap.cs`, `DragPlayer.cs` | `src/objects/MovingPlatform.gd` with Godot `AnimatableBody2D` carry behavior |
| `Deadly.cs` | `src/objects/Spikes.gd`, `src/objects/SawTrap.gd` |
| `NextLevel.cs` | `src/objects/Portal.gd` plus MetSys room loading |

## Verification

- `Godot --headless --path . --quit-after 2`: main scene opens from the new DanielDFY-style menu.
- `.scratch/RouteRunner.tscn`: loads Room1 through Room5 successfully.
- `.scratch/DanielFeatureRunner.tscn`: verifies Room2 switch opens door, switch triggers falling trap, unstable platform triggers, gunner spawns projectile.

## Remaining Gaps

- Unity scenes `Spawn`, `Level1`, and `Level2` are represented as Godot rooms rather than rebuilt one-to-one.
- Menu and pause use the original visual resources but are not exact pixel layouts.
- Player animation coverage is functional, but not every DanielDFY animator trigger has a distinct matching animation.
- Some DanielDFY atlas sprites are used as cropped or representative sprites instead of full Unity atlas slicing.
