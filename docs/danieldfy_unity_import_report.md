# DanielDFY Unity Import Report

Source: `cloned_repos/Hollow-Knight-Imitation/Hollow Knight`

This report is generated from Unity YAML scenes/prefabs. It maps DanielDFY objects to existing Godot scenes/scripts so future copying is repeatable instead of hand-authored.

## Source Asset Mirror

- Source images: `cloned_repos/Hollow-Knight-Imitation/Hollow Knight/Assets/Resources/Images` (119 image files)
- Godot mirror: `assets/sprites/danieldfy/Images` (119 image files, 119 `.import` files)
- Missing mirrored source images: 0

## Summary

| Scene | Objects | Scripts | Sprites | Colliders | Mapped | Ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Assets/Scenes/HUD.unity | 27 | 21 | 0 | 0 | 2 | 7% |
| Assets/Scenes/Level1.unity | 52 | 10 | 43 | 34 | 48 | 92% |
| Assets/Scenes/Level2.unity | 57 | 4 | 47 | 16 | 53 | 93% |
| Assets/Scenes/Menu.unity | 20 | 16 | 1 | 0 | 2 | 10% |
| Assets/Scenes/Spawn.unity | 9 | 1 | 5 | 4 | 8 | 89% |

## Generated Godot Blueprints

- `Assets/Scenes/HUD.unity` -> `src/world/imported/DanielDFY_HUD_Imported.tscn` (2 mapped objects)
- `Assets/Scenes/Level1.unity` -> `src/world/imported/DanielDFY_Level1_Imported.tscn` (48 mapped objects)
- `Assets/Scenes/Level2.unity` -> `src/world/imported/DanielDFY_Level2_Imported.tscn` (53 mapped objects)
- `Assets/Scenes/Menu.unity` -> `src/world/imported/DanielDFY_Menu_Imported.tscn` (2 mapped objects)
- `Assets/Scenes/Spawn.unity` -> `src/world/imported/DanielDFY_Spawn_Imported.tscn` (8 mapped objects)

## Generated Visual Layers

- `Assets/Scenes/HUD.unity` -> `src/world/imported/DanielDFY_HUD_VisualLayer.tscn` (0 sprite nodes)
- `Assets/Scenes/Level1.unity` -> `src/world/imported/DanielDFY_Level1_VisualLayer.tscn` (41 sprite nodes)
- `Assets/Scenes/Level2.unity` -> `src/world/imported/DanielDFY_Level2_VisualLayer.tscn` (45 sprite nodes)
- `Assets/Scenes/Menu.unity` -> `src/world/imported/DanielDFY_Menu_VisualLayer.tscn` (1 sprite nodes)
- `Assets/Scenes/Spawn.unity` -> `src/world/imported/DanielDFY_Spawn_VisualLayer.tscn` (2 sprite nodes)

## Generated Gameplay Layers

- `Assets/Scenes/HUD.unity` -> `src/world/imported/DanielDFY_HUD_GameplayLayer.tscn` (0 gameplay objects)
- `Assets/Scenes/Level1.unity` -> `src/world/imported/DanielDFY_Level1_GameplayLayer.tscn` (42 gameplay objects)
- `Assets/Scenes/Level2.unity` -> `src/world/imported/DanielDFY_Level2_GameplayLayer.tscn` (22 gameplay objects)
- `Assets/Scenes/Menu.unity` -> `src/world/imported/DanielDFY_Menu_GameplayLayer.tscn` (1 gameplay objects)
- `Assets/Scenes/Spawn.unity` -> `src/world/imported/DanielDFY_Spawn_GameplayLayer.tscn` (6 gameplay objects)

## Godot Target Counts

### Assets/Scenes/HUD.unity

- `res://src/ui/HUD.gd`: 2

Mapped sample:

- `HealthDisplay` -> `res://src/ui/HUD.gd` (n/a, scripts: HealthDisplay, unknown_script_30649d3a9faa99c48a7b1166b86bf2a0)
- `HUD` -> `res://src/ui/HUD.gd` (n/a, scripts: HUD, unknown_script_dc42784cf147c0c48a680349fa168899, unknown_script_0cd44c1031e13a943bb63640046fad76)

Unmapped scripted objects:

- `bottom` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Buttons` scripts=unknown_script_59f8146938fff824cb5fd77236b75775
- `EventSystem` scripts=unknown_script_4f231c4fb786f3946a6b90b886c48677, unknown_script_76c392e42b5098c458856cdf6ecaaaa1
- `Heart1` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Heart2` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Heart3` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Heart4` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Heart5` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Left` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Left` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Logo` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Mask` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc

### Assets/Scenes/Level1.unity

- `Sprite2D decoration`: 6
- `StaticBody2D platform`: 13
- `StaticBody2D wall`: 13
- `StaticBody2D/Sprite2D`: 5
- `res://src/objects/Portal.tscn`: 1
- `res://src/objects/Spikes.tscn`: 7
- `res://src/objects/SwitchTrigger.tscn`: 2
- `res://src/objects/TriggerDoor.tscn`: 1

Mapped sample:

- `airwall1` -> `StaticBody2D wall` (x=-5.46, y=5.03, scripts: -)
- `airwall1 (1)` -> `StaticBody2D wall` (x=114.41, y=16.98, scripts: -)
- `AirWalls` -> `StaticBody2D wall` (x=0.00, y=0.00, scripts: -)
- `ancient_wall_pieces_0007_Color-Balance-1-copy-13` -> `StaticBody2D wall` (x=36.95, y=24.10, scripts: -)
- `antique_sign_main` -> `Sprite2D decoration` (x=103.43, y=13.43, scripts: -)
- `direction_sign_breakable_0006_Layer-0` -> `Sprite2D decoration` (x=103.44, y=11.91, scripts: -)
- `floor1 (1)` -> `StaticBody2D platform` (x=-2.81, y=-5.69, scripts: -)
- `floor1 (2)` -> `StaticBody2D platform` (x=11.67, y=-7.64, scripts: -)
- `floor1 (3)` -> `StaticBody2D platform` (x=31.41, y=-0.03, scripts: -)
- `floor1 (4)` -> `StaticBody2D platform` (x=14.12, y=9.98, scripts: -)
- `floor1 (5)` -> `StaticBody2D platform` (x=8.46, y=15.69, scripts: -)
- `floor1 (6)` -> `StaticBody2D platform` (x=50.19, y=18.33, scripts: -)
- `floor1 (7)` -> `StaticBody2D platform` (x=75.27, y=6.53, scripts: -)
- `floor1 (8)` -> `StaticBody2D platform` (x=113.10, y=8.00, scripts: -)
- `Floors` -> `StaticBody2D platform` (x=0.00, y=0.00, scripts: -)
- `fung_floor_03` -> `StaticBody2D platform` (x=1.25, y=-3.77, scripts: -)

### Assets/Scenes/Level2.unity

- `Sprite2D decoration`: 30
- `StaticBody2D platform`: 8
- `StaticBody2D wall`: 4
- `StaticBody2D/Sprite2D`: 5
- `res://src/objects/Spikes.tscn`: 3
- `res://src/objects/SwitchTrigger.tscn`: 1
- `res://src/objects/TriggerDoor.tscn`: 1
- `res://src/world/Game.gd`: 1

Mapped sample:

- `airwall1` -> `StaticBody2D wall` (x=127.07, y=8.50, scripts: -)
- `AirWalls` -> `StaticBody2D wall` (x=0.00, y=0.00, scripts: -)
- `bathhouse_bouquet_0000_8` -> `Sprite2D decoration` (x=29.89, y=4.86, scripts: -)
- `books1` -> `Sprite2D decoration` (x=7.81, y=3.95, scripts: -)
- `cabinet1` -> `Sprite2D decoration` (x=-7.50, y=4.51, scripts: -)
- `ceiling1` -> `StaticBody2D platform` (x=24.13, y=16.15, scripts: -)
- `chain_01` -> `StaticBody2D/Sprite2D` (x=36.33, y=11.11, scripts: -)
- `chain_01 (1)` -> `StaticBody2D/Sprite2D` (x=43.07, y=11.11, scripts: -)
- `chain_01 (2)` -> `StaticBody2D/Sprite2D` (x=49.84, y=11.11, scripts: -)
- `chain_01 (3)` -> `StaticBody2D/Sprite2D` (x=56.52, y=11.11, scripts: -)
- `chandelier_0008_broke-chand1` -> `Sprite2D decoration` (x=12.77, y=13.60, scripts: -)
- `chandelier_0008_broke-chand1 (1)` -> `Sprite2D decoration` (x=26.30, y=13.60, scripts: -)
- `chandelier_0008_broke-chand1 (2)` -> `Sprite2D decoration` (x=39.80, y=13.50, scripts: -)
- `column3` -> `Sprite2D decoration` (x=-4.81, y=5.78, scripts: -)
- `column3 (1)` -> `Sprite2D decoration` (x=3.11, y=5.78, scripts: -)
- `door_entry` -> `res://src/objects/TriggerDoor.tscn` (x=-0.88, y=6.27, scripts: -)

### Assets/Scenes/Menu.unity

- `Sprite2D decoration`: 1
- `res://src/ui/MainMenu.tscn`: 1

Mapped sample:

- `Background` -> `Sprite2D decoration` (n/a, scripts: unknown_script_fe87c0e1cc204ed48ad3b37840f39efc)
- `Menu` -> `res://src/ui/MainMenu.tscn` (n/a, scripts: Menu, unknown_script_dc42784cf147c0c48a680349fa168899, unknown_script_0cd44c1031e13a943bb63640046fad76)

Unmapped scripted objects:

- `Buttons` scripts=unknown_script_59f8146938fff824cb5fd77236b75775
- `EventSystem` scripts=unknown_script_4f231c4fb786f3946a6b90b886c48677, unknown_script_76c392e42b5098c458856cdf6ecaaaa1
- `Left` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Left` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Left` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `LoadButton` scripts=unknown_script_4e29b1a8efbd4b44bb3f3716e73f07ff, unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `QuitButton` scripts=unknown_script_4e29b1a8efbd4b44bb3f3716e73f07ff, unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Right` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Right` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Right` scripts=unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `StartButton` scripts=unknown_script_4e29b1a8efbd4b44bb3f3716e73f07ff, unknown_script_fe87c0e1cc204ed48ad3b37840f39efc
- `Text` scripts=unknown_script_5f7201a12d95ffc409449d95f23cf332

### Assets/Scenes/Spawn.unity

- `Sprite2D decoration`: 2
- `StaticBody2D platform`: 2
- `StaticBody2D wall`: 3
- `res://src/objects/Portal.tscn`: 1

Mapped sample:

- `airwall_left` -> `StaticBody2D wall` (x=-7.78, y=-2.55, scripts: -)
- `airwall_right` -> `StaticBody2D wall` (x=4.14, y=-0.68, scripts: -)
- `AirWalls` -> `StaticBody2D wall` (x=4.14, y=-0.68, scripts: -)
- `ArrowHint` -> `Sprite2D decoration` (x=-3.65, y=-3.18, scripts: -)
- `NextLevel` -> `res://src/objects/Portal.tscn` (x=0.06, y=-6.74, scripts: NextLevel)
- `platform_spawn` -> `StaticBody2D platform` (x=-2.45, y=-2.82, scripts: -)
- `Platforms` -> `StaticBody2D platform` (x=0.00, y=-3.37, scripts: -)
- `SpawnBG` -> `Sprite2D decoration` (x=0.08, y=-0.83, scripts: -)
