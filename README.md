# Chicken Alien Hunt

A Roblox Rojo MVP for a multiplayer mystery-horror social deduction game. Players investigate NPCs, find clues, accuse hidden Galloid aliens, then eliminate revealed aliens before the round ends.

## Windows Setup

Install these first:

- Roblox Studio
- Rojo Studio plugin from the Roblox Creator Store
- Git for Windows
- Rokit for Windows

Then open PowerShell in the project folder:

```powershell
cd C:\path\to\chicken-alien-hunt
rokit install
```

This installs the pinned Roblox tooling from `rokit.toml`, including Rojo and Luau.

## Run In Roblox Studio

Start the Rojo server from PowerShell:

```powershell
rojo serve default.project.json
```

Then:

1. Open Roblox Studio.
2. Create or open a blank place.
3. Open the Rojo plugin.
4. Connect to `localhost:34872`.
5. Press Play in Studio.

The project syncs into Studio with this layout:

- `src/server` -> `ServerScriptService.Server`
- `src/client` -> `StarterPlayer.StarterPlayerScripts.Client`
- `src/shared` -> `ReplicatedStorage.Shared`

## Quick Test

After pressing Play:

1. Confirm the mission HUD appears.
2. Wait for intermission to finish.
3. Confirm the farm-town arena, NPCs, and clue props spawn.
4. Inspect clues with the `Inspect Clue` prompt.
5. Accuse NPCs with the `Accuse` prompt.
6. Use the `Alien Zapper` on revealed aliens.
7. Confirm revealed aliens show a world health bar and can be eliminated.
8. Use the `Suspicious`, `Clue`, and `Help` ping buttons during an active round.

## Windows Studio Testing Guide

Use this checklist when testing in Roblox Studio on Windows.

### Single-Player Smoke Test

1. Start `rojo serve default.project.json` from PowerShell.
2. Connect Roblox Studio through the Rojo plugin.
3. Press Play.
4. Confirm the mission HUD appears.
5. Confirm your class, health, round phase, timer, and entity count appear.
6. Wait for intermission to finish.
7. Confirm FarmTown appears with the well, store, barn, silo, coop, windmill, truck, NPCs, and clue props.
8. Inspect each clue with the `Inspect Clue` prompt.
9. Confirm evidence appears in the HUD without revealing secret alien identities.
10. Confirm the suspect list changes as clues are discovered.

### Accusation And Combat Test

1. Accuse an NPC with the `Accuse` prompt.
2. Confirm a wrong accusation shows feedback, reduces the timer, and raises threat pressure.
3. Keep accusing until an alien is revealed.
4. Confirm the revealed alien changes appearance and gets a world health bar.
5. Equip `Alien Zapper`.
6. Stand close to the revealed alien and activate the tool.
7. Confirm weapon feedback appears in the HUD.
8. Confirm the alien health bar drops after hits.
9. Confirm the alien darkens and stops fighting when eliminated.
10. Confirm eliminating all aliens ends the round with a player win.

### Player Ping Test

1. Wait until the round is active.
2. Press `Suspicious`.
3. Confirm all players receive a `TEAM PING` HUD message.
4. Confirm a temporary yellow world marker appears at your position.
5. Press another ping immediately and confirm cooldown blocks spam.
6. After cooldown, press `Clue` and confirm a blue marker appears.
7. After cooldown, press `Help` and confirm a red marker appears.
8. Confirm pings do not reveal secret alien identities.

### Class Ability Test

Test each class from the HUD class buttons:

- Hunter: reveal an alien, press `Use Class Ability`, and confirm the alien is stunned.
- Investigator: stand near an unrevealed NPC, use the ability, and confirm scan feedback does not reveal secret identity.
- Engineer: use the ability and confirm a sensor appears.
- Medic: take damage, use the ability, and confirm health is restored.
- Scout: stand near an NPC, use the ability, and confirm the target is marked.

### Local Multiplayer Test

In Studio:

1. Open the `Test` tab.
2. Set players to `2` or more.
3. Start a local server test.
4. Confirm each player gets a HUD and class.
5. Confirm clues discovered by one player update for all players.
6. Confirm accusations, alien reveals, combat damage, and round results replicate to all players.
7. Confirm clients never see secret alien identities before reveal.

### Failure Checks

Watch the Studio Output window for errors while testing:

- no red runtime errors during server bootstrap
- no missing remote warnings
- no missing `Shared.Config` or `Shared.MapLayout` errors
- no clue or NPC spawn errors
- no combat errors when using `Alien Zapper`

If something fails, restart Play mode after confirming Rojo is still connected.

## Validation

From PowerShell:

```powershell
rojo build default.project.json --output build.rbxlx
rojo sourcemap default.project.json
luau src\shared\Config.lua
```

Full behavior still needs Roblox Studio because server and client files depend on Roblox runtime globals such as `game`, `Instance`, `Color3`, and `Vector3`.

## MVP Scope

Keep the MVP simple:

- server owns all game truth
- client never receives secret alien identities until reveal
- no monetization yet
- no data saving yet
- no advanced UI yet
- small modular services over giant scripts
