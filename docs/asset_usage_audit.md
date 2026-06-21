# Asset Usage Audit

Date: 2026-06-21

Goal: use available project assets first. Do not hand-build visuals when a usable imported asset already exists.

## Usable Assets Confirmed In Runtime

| Asset group | Runtime use |
| --- | --- |
| `assets/sprites/player/**` | Player idle/walk/jump/fall/dash/wall/attack animation frames loaded by `src/player/Player.gd`. |
| `assets/sprites/attack_effects.png` | Nail slash visual in `src/player/Player.tscn`. |
| `assets/sprites/hollow_imitation/framework/**` | Room1 floor and wall/window structure. |
| `assets/sprites/hollow_imitation/decoration/**` | Room1 columns, chains, lamps, fences. |
| `assets/sprites/hollow_imitation/door_entry/**` | Room exits and door dressing. |
| `assets/sprites/hollow_imitation/enemy/ground_insect1.png` | Crawlid enemy. |
| `assets/sprites/hollow_imitation/enemy/fly_insect1.png` | Vengefly enemy. |
| `assets/sprites/hollow_imitation/enemy/atlas0_61.png` | Gunner enemy. |
| `assets/sprites/godot_hk_controller/Warrior_SheetnoEffect.png` | Room3 controller echo and MantisWarrior pose underlay. |
| `assets/sprites/UI/health_full.png`, `health_empty.png` | HUD mask display. |
| `assets/sprites/hollow_imitation/menu/**` | Main menu and pause visual frame. |
| `assets/sprites/hollow_imitation/trap/**` | Saw/spike hazards. |
| `assets/sprites/hollow_imitation/platform/**` | Room floors/platforms and unstable platforms. |
| `assets/audio/Player*.wav`, `assets/audio/false_knight/*.wav` | Jump, hit, damage, boss SFX. |

## Hand-Built Parts Still Allowed

| Part | Why not replaced |
| --- | --- |
| Room1 light bloom polygons/gradient sprites | No direct imported HK-style light cone texture exists; built from Godot primitives, low risk. |
| Mantis mask/eye/spear overlay | Imported warrior sheet is human-shaped; overlay keeps HK mask/spear read while still using sheet as pose source. |
| Simple ColorRect rails/fades | Structural composition helpers; no matching imported rail/fade asset found. |

## Next Rule

Before adding new custom art, search `assets/` first and update this audit.
