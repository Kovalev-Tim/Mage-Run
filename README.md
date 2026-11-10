# RIFT RUN — Archmage corridor MVP

RIFT RUN is a code-first Roblox Archmage simulator. Players spawn together on the hub platform, choose from nine mage archetypes, then walk into one continuous corridor and clear ten sequential zones. Each zone has five opponents; Zones 5 and 10 end with a boss and a special attack. Defeating enemies grants Battle Cups; clearing a zone unlocks the next one. Server code owns enemy health, rewards, purchases, and progression.

## Before you press Play

1. Install Rojo CLI and the Rojo Studio plugin (see `TRANSFER-TO-STUDIO.md`).
2. Add the upstream **ProfileStore** ModuleScript at `src/ServerScriptService/Packages/ProfileStore.lua`. Use the source from [MadStudioRoblox/ProfileStore](https://github.com/MadStudioRoblox/ProfileStore), pin a release/commit, and keep its license.
3. Open a published **development** experience, enable API Services only on that test experience, and test data there. Never point Studio API access at production player data.
4. Connect Rojo and sync. See transfer steps below.

## Core loop

- Walk from the hub into Zone 1. Enemies spawn in the corridor.
- Enemies within range are attacked automatically. Press **Q** and **E** to cast the selected mage's area skills.
- Defeat every enemy in a zone to earn its Battle Cup clear reward and unlock the next zone.
- Spend Battle Cups on Skill Mastery upgrades, mage unlocks, or eggs.
- Stand still in the Meditation Pool to earn 3 Battle Cups every 30 seconds; use its focus stone to buy Skill Mastery ranks.
- Hold **Shift** to sprint. Enemies steer around one another so they do not pile into one point.

Choose from nine mage archetypes on the StartingPlatform, clear of the corridor entrance. Their cup costs and M1/Q/E damage are shown on smaller stands, ordered from lowest to highest. Skill Mastery upgrades scale Q/E damage with Battle Cups while M1 damage follows the selected archetype. E skills use expanding rune rings and particle bursts. The pet inventory lets players equip and unequip owned pets. Egg prompts offer one hatch or a three hatch option gated by the configurable Triple Hatch gamepass ID in `MonetizationConfig.lua`; hatching includes a reveal animation. Equipped pets follow the Archmage and are visible to other players. Defeat returns players to the hub after a short respawn, and clearing a zone restores some health. The hub has three egg types and a portal to a separate rebirth-themed dimension.

Pets provide combat and Battle Cup bonuses. Enchantments are a later progression milestone. The rebirth-themed dimension is currently an explorable portal area; rebirth progression and other Robux purchases are not implemented yet.

## Project layout

- `src/ReplicatedStorage/Shared/Config`: zone, enemy, upgrade, meditation, monetization, and companion definitions.
- `src/ServerScriptService`: profile lifecycle, corridor map, zone progression, server combat, rewards, meditation, and upgrades.
- `src/StarterPlayer/StarterPlayerScripts`: corridor HUD, journal, and input controls.
- `TRANSFER-TO-STUDIO.md`: Rojo and Studio setup instructions.

Art is still blockout quality. Replace it with original meshes, animation, terrain, audio, and effects in Studio as the game develops.
