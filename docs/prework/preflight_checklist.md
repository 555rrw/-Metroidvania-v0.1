# Prework Gate Checklist

Use this before starting any new feature or importing any external repo/tool/asset.

## 1. Workspace Safety

- Run `git status --short --branch`.
- Identify dirty files and decide whether they are part of this work.
- Do not stage unrelated dirty files.
- Keep external references out of Godot import paths unless intentionally adopted.

## 2. License Audit

For every new repo, plugin, or asset:

- Record source URL.
- Record license and source of license info.
- Mark commercial use: yes/no/unknown.
- Mark modification allowed: yes/no/unknown.
- Mark attribution required: yes/no/unknown.
- If unknown, candidate status becomes **Hold**.

## 3. Godot Version Audit

- Prefer Godot 4.5+ references.
- Godot 4.0-4.4 references are concept-only until loaded in 4.7.
- Godot 3 references are design references only.
- Plugins must be verified in a scratch branch before installation.

## 4. Merge Risk Audit

Before adoption, answer:

- Does this touch `project.godot`, input map, autoloads, or editor plugins?
- Does this conflict with MetSys save data, room loading, or minimap?
- Does this require C#, GDExtension, native binaries, or export templates?
- Can it be removed cleanly if the trial fails?

## 5. Feature Fit Audit

Each candidate needs one exact use:

- System to borrow.
- Data structure to study.
- Tuning value to compare.
- Asset role to fill.
- Test capability to add.

If the answer is "use everything", reject the candidate until narrowed.

## 6. Verification Gate

Minimum verification before work starts:

```powershell
& 'C:\Users\0000\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 2
git diff --check
```

Minimum verification before finishing:

- Main scene headless smoke exits 0.
- All touched scenes load or are covered by a route verifier.
- `git diff --check` exits 0.
- `git status --short` shows only intended files.

## 7. Adoption Rule

- Reference docs may be committed immediately.
- Plugin installs require a separate implementation task.
- Asset imports require license note and attribution file update.
- Source repos should not be copied into `res://` unless `.gdignore` or equivalent isolation is planned first.
