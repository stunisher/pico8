Howzer-Z — Design Notes

Elevator pitch
- Top-down action/survival with a central home base. Leave base to go outside (advances day), fight enemies, gather resources, return to craft/upgrade, repeat.

Core loop
- Inside base: rest, craft deployables, manage resources.
- Leave base: day increments, world randomizes, enemies spawn off-screen and attack.
- Survive waves/days; score by days survived + kills.

High-level mechanics (MVP)
- Player: 8‑way movement, facing, basic attack (ranged projectile first), health.
- Base: interior/exterior state; leaving triggers next day and respawn.
- Enemies: spawn off-screen, simple seek AI toward player or base, drop resources on kill.
- Resources & crafting: enemies/environment drop items; simple recipe to craft one deployable (turret/trap).
- Deployables: placeable objects that auto-attack or block; finite HP or lifetime.
- Day progression: increase spawn rate, enemy HP, or enemy count per day (simple scaling formula).
- HUD: day counter, player HP, basic inventory/crafting indicator.

Scalability & code organization
- Keep `main.lua` as the minimal game loop (init/update/draw), load systems.
- `cfg.lua` for tuning constants (speeds, spawn rates, sizes).
- `entity.lua` for prototype/OOP helper and base archetype fields.
- `entities.lua` manager for active instances (spawn, update_all, draw_all, remove).
- `player.lua`, `enemies.lua`, `projectiles.lua` implement system-specific behaviors.
- Use archetype data tables (`archetypes = { zombie = {speed=..., hp=...} }`) and `spawn_entity(archetype,x,y)`.
- Use pooling for high-churn objects (projectiles/particles) to avoid frequent allocations.

Animation & controls
- Keep simple: `anim` counter per entity toggles walk frames; preserve last facing when idle.
- Controls: arrow keys for movement, `z` to attack (or craft/place inside base).

Notes & ideas backlog (short)
- Melee attack option and weapon types.
- Multiple enemy types (slow tank, fast skitter, ranged caster).
- Resource types (meat, scrap, cloth) and multi-step crafting.
- Day events (weather, night waves, special boss spawns).
- Save high score (days survived) locally.
- Randomized portals (maybe one time use), that teleport you back home

How to add a mechanic
- Add a short entry under "High-level mechanics" or "Notes & ideas backlog" with one-line summary + acceptance test.
- If code needed, create a small task in the todo list and implement as a small system with unit-like checks (e.g., spawn test scene).

Change log
- 2026-01-10: Initial notes and organization scaffold added by Copilot assistant.

