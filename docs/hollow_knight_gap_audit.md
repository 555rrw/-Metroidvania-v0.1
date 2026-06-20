# Hollow Knight Gap Audit

Date: 2026-06-20

## Current Verdict

This project is now a playable Godot vertical slice, not a full Hollow Knight clone. It targets the first playable version: movement, combat, MetSys rooms, ability progression, one boss, one spell, one secret shortcut.

## Closed for v1

- Movement has coyote time, jump buffer, variable jump, dash, double jump, wall slide/jump, pogo, and camera look up/down.
- Combat has directional nail hitboxes, hit pause, recoil, Soul gain, Focus heal, and Vengeful Spirit.
- World has five rooms, dash gate, boss gate/reward, spell shrine, secret cache, shortcut return, save point, minimap.
- Boss has anticipation, leap, slam, shockwaves, stagger, phases, reward drop.
- HUD hides integration debug text and shows health, Soul, unlock popup, minimap.

## Still Below Hollow Knight

- Art remains mixed-source prototype art, with ColorRect collision silhouettes still visible in several rooms.
- Enemy roster is tiny: Crawlid, Vengefly, False Knight only.
- No charm system, currency, map vendor, NPCs, benches as full state hubs, menu flow, or narrative layer.
- Combat lacks full spell set, nail upgrades, charm interactions, enemy-specific hit reactions, and full-screen hitstop/audio polish.
- World is linear with one shortcut; Hollow Knight's real strength is dense routing, secrets, and backtracking pressure.

## Next Upgrade Priority

1. Replace visible ColorRect platforms with textured tile/prop assemblies while keeping collision nodes hidden or subtle.
2. Add two more enemy types and one mini-encounter room.
3. Turn SavePoint into bench behavior: rest animation, map update, heal, save, respawn point.
4. Add map reveal rules: unexplored, explored, bench/map station reveal.
5. Add spell tutorial and one breakable wall gated by Vengeful Spirit.
