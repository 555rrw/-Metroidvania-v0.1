# External Reference and Tool Pool

Research date: 2026-06-20

Purpose: prepare the next work cycle before importing code, plugins, or assets. This registry is a gate. Candidates stay as references until license, Godot version, merge risk, feature fit, and verification are checked.

## Decision Codes

- **Primary reference**: read first; likely useful now.
- **Secondary reference**: useful for comparison; do not copy directly without a fit check.
- **Candidate tool**: evaluate in a scratch branch or isolated copy before adoption.
- **Hold**: do not adopt until a specific risk is resolved.

## Game and System References

| Area | Candidate | License | Godot signal | Status | Use before coding | Risks |
| --- | --- | --- | --- | --- | --- | --- |
| Full metroidvania | [wheafun/bread-adventure](https://github.com/wheafun/bread-adventure) | Apache-2.0 | Godot 4.5 | Primary reference | Room flow, items, save, settings, enemy organization | Full game structure may be larger than this slice needs |
| Full metroidvania | [uheartbeast/metroidvania-godot-4](https://github.com/uheartbeast/metroidvania-godot-4) | MIT | Godot 4.0 | Secondary reference | Small tutorial-scale progression and ability patterns | Older 4.0 project; do not adopt values blindly |
| Platform feel | [Noah-Erz/Ultimate-Platformer-Controller-2D](https://github.com/Noah-Erz/Ultimate-Platformer-Controller-2D) | MIT | Godot 4.x asset, no project feature string found | Primary reference | Corner correction, dash pause, wall jump buffer, input tuning | Must adapt to current `Player.gd`, not replace it wholesale |
| Boss/AI architecture | [derkork/godot-statecharts](https://github.com/derkork/godot-statecharts) | MIT | Godot 4.0 | Candidate tool | Formalize False Knight and future bosses when state count grows | Adds plugin dependency and scene nodes |
| Boss/AI architecture | [limbonaut/limboai](https://github.com/limbonaut/limboai) | MIT | Godot 4 plugin | Hold | Behavior trees for complex enemy ecosystems | C++/extension footprint; higher integration and export risk |
| Camera | [ramokz/phantom-camera](https://github.com/ramokz/phantom-camera) | MIT | Godot 4 plugin | Candidate tool | Room framing, boss camera, look zones, smooth transitions | Current custom camera is simple; avoid plugin unless camera needs outgrow it |
| Level design pipeline | [heygleeson/godot-ldtk-importer](https://github.com/heygleeson/godot-ldtk-importer) | MIT | Godot 4.3 | Hold | LDtk room authoring if hand-written `.tscn` becomes too slow | Migration cost; must coexist with MetSys MapData |

## Development Tools

| Area | Candidate | License | Godot signal | Status | Use before coding | Risks |
| --- | --- | --- | --- | --- | --- | --- |
| Scene/unit tests | [godot-gdunit-labs/gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | MIT | Godot 4.6/C# feature string | Primary candidate | Regression tests for scene load, save, abilities, combat objects | Plugin install needed; first trial must be isolated |
| Scene/unit tests | [bitwes/Gut](https://github.com/bitwes/Gut) | License unresolved from GitHub API/raw license check | Godot 4.6 | Hold | Alternative GDScript test framework | Do not adopt until license file or official license source is verified |
| Headless verification | [Godot command line/headless docs](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html) | Official docs | Godot 4.7 docs | Required baseline | Run smoke and scene route checks every cycle | Headless screenshot capture can hang; do not make screenshots required |
| Aseprite workflow | [viniciusgerevini/godot-aseprite-wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard) | MIT | Godot 4.5 | Primary candidate | Import player/enemy animations into SpriteFrames or AnimationPlayer | Requires Aseprite source workflow |
| Aseprite workflow | [nklbdev/godot-4-aseprite-importers](https://github.com/nklbdev/godot-4-aseprite-importers) | MIT | Godot 4 addon | Secondary candidate | Compare importer model if Aseprite Wizard is too heavy | Older last push; less active |
| SFX | [tomeyro/godot-sfxr](https://github.com/tomeyro/godot-sfxr) | MIT | Godot 4.1 | Candidate tool | Generate placeholder dash, hit, bench, spell, telegraph SFX | Godot 4.1 feature string; verify in 4.7 scratch first |
| SFX | [jsfxr](https://sfxr.me/) | Browser tool/library | N/A | Secondary tool | Generate WAV-like source sounds outside Godot | Manual export/import workflow |

## Asset Pools

| Pool | License policy | Status | Use before coding | Risk |
| --- | --- | --- | --- | --- |
| [Kenney](https://kenney.nl/assets) | Kenney support page states asset-page game assets are CC0/public-domain licensed and commercial use is allowed | Primary pool | UI, props, placeholder VFX/SFX, non-HK-specific art | Per-asset license file still must be retained |
| [OpenGameArt](https://opengameart.org/) | Per-asset license; accepts CC0, OGA-BY, CC-BY, CC-BY-SA, GPL/LGPL, public-domain-like terms | Secondary pool | Tilesets, ambiance, sound, enemy placeholders | Each asset needs individual attribution/license review |

## Recommended Defaults for Next Cycle

- Use `bread-adventure`, `metroidvania-godot-4`, and `Ultimate-Platformer-Controller-2D` as read-only references.
- Trial **GdUnit4** before GUT because license metadata is clean and scene testing is explicit.
- Trial **Aseprite Wizard** before other Aseprite importers because it is active and Godot 4.5-oriented.
- Keep **Phantom Camera**, **State Charts**, **LimboAI**, and **LDtk importer** as candidates, not installed dependencies.
- Use **Kenney** first for new legal placeholder assets; use OpenGameArt only after per-asset attribution is documented.

## Source Metadata Snapshot

GitHub metadata was gathered from the public GitHub API on 2026-06-20. Fields checked: license, stars, forks, default branch, pushed date, archive status, primary language, topics, and `project.godot` feature string when available.
