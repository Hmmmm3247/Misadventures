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
2. Confirm a wrong accusation shows emergency feedback, reduces the timer, triggers a screen pulse, and raises threat pressure.
3. Keep accusing until an alien is revealed.
4. Confirm the revealed alien changes appearance and gets a world health bar.
5. Move away from the revealed alien and confirm it starts chasing nearby living players.
6. Confirm the chased player receives `CHASE WARNING` feedback and a short red screen pulse.
7. Confirm the chase-stop message appears when the alien loses pursuit.
8. Confirm a stunned alien pauses chase briefly.
9. Confirm the final chase stop distance feels close but not unfair. Current value: `Config.RevealedAlienChase.StopDistance = 9`.
10. Confirm wrong accusations temporarily make revealed aliens feel more urgent.
11. Confirm alarm/map event feedback appears after a wrong accusation.
12. Equip `Alien Zapper`.
13. Stand close to the revealed alien and activate the tool.
14. Confirm weapon feedback appears in the HUD.
15. Confirm the alien health bar drops after hits.
16. Confirm the alien darkens and stops fighting when eliminated.
17. Confirm eliminating all aliens ends the round with a player win.

### NPC Ambient Behavior Test

During an active round, watch unrevealed NPCs for:

- idle rotations
- small wandering movement
- short pauses
- occasional clustering near landmarks such as the store, barn, well, silo, coop, truck, and observation pole

Confirm:

1. NPCs do not move constantly.
2. NPCs do not all cluster at the same landmark.
3. Clustering makes the map feel alive without making accusations too noisy.
4. Hidden alien tells still stand out from ordinary ambient movement.

Tune these first if NPCs feel wrong:

- `Config.NPCBehavior.MoveChance`
- `Config.NPCBehavior.ClusterChance`
- `Config.NPCBehavior.RandomFacingChance`
- `Config.NPCBehavior.IdlePauseMin`
- `Config.NPCBehavior.IdlePauseMax`

### Chase And Tension Tuning Test

Use debug controls for this pass.

1. Enable debug testing in `Config.DebugTesting`.
2. Press `Skip Active`.
3. Press `Reveal 1`.
4. Move away from the revealed alien and observe chase.
5. Press `Chase Test` to place a revealed alien near your player.
6. Press `Wrong Penalty` and observe attack/chase pressure.
7. Press `Aggression` and check the HUD/Output multiplier readout.
8. Repeat with different values.

Tune in this order:

1. `Config.RevealedAlienChase.Speed`
2. `Config.RevealedAlienChase.StopDistance`
3. `Config.RevealedAlienChase.Range`
4. `Config.RevealedAlienAttack.Cooldown`
5. `Config.WrongAccusation.TimePenalty`
6. `Config.WrongAccusation.AggressionMultiplier`
7. `Config.WrongAccusation.ChaseAggressionMultiplier`
8. `Config.WrongAccusation.ScreenPulseDuration`

Good first targets:

- Chase should feel dangerous, but a healthy player should have a moment to react.
- Stop distance should keep the alien visually close without sitting inside the player.
- Attack cooldown should punish staying close, not instantly delete the player.
- Wrong accusation pressure should be scary, but not usually round-ending by itself.
- Screen pulse should be noticeable, not blinding.

### Debug Control Test

Debug controls only appear when `Config.DebugTesting.Enabled` and `Config.DebugTesting.ControlsEnabled` are both true.

Test each button:

- `Reveal 1`: reveals one hidden alien through the normal server reveal path.
- `Reveal All`: reveals all current aliens.
- `Skip Active`: starts an active round quickly.
- `Wrong Penalty`: applies the wrong accusation penalty without needing to find a false NPC.
- `Chase Test`: reveals/places an alien near the player for chase testing.
- `Aggression`: prints current attack/chase multipliers to Output and sends HUD feedback.

Confirm:

1. Debug controls do not appear when debug testing is disabled.
2. Debug reveals do not expose alien identity until the server reveal event fires.
3. `Skip Active` does not break the round loop.
4. `Wrong Penalty` reduces active time and triggers emergency feedback.
5. `Chase Test` places the alien at a useful test distance.
6. `Aggression` reports attack and chase multipliers clearly.

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
- no debug command errors when debug testing is enabled
- no repeated chase warning spam
- no NPC clustering errors from temporary ping/sensor props

If something fails, restart Play mode after confirming Rojo is still connected.

## Validation

From PowerShell:

```powershell
rojo build default.project.json --output build.rbxlx
rojo sourcemap default.project.json
luau src\shared\Config.lua
```

Full behavior still needs Roblox Studio because server and client files depend on Roblox runtime globals such as `game`, `Instance`, `Color3`, and `Vector3`.

## Debug Testing

`src/shared/Config.lua` includes `Config.DebugTesting`, which is off by default.

For faster local Studio testing, temporarily set:

```lua
Config.DebugTesting = {
	Enabled = true,
	ControlsEnabled = true,
	CommandCooldown = 0.5,
	MinPlayersOverride = 1,
	IntermissionLength = 3,
	RoundLength = 90,
	ResultsLength = 6,
	RevealFirstAlienAfter = 5,
	ChaseTestSpawnDistance = 24
}
```

This keeps the server authoritative. If `RevealFirstAlienAfter` is set, the server reveals one alien through the normal public reveal flow after the round starts. Turn debug testing back off before normal playtests.

When `Enabled` and `ControlsEnabled` are both true, the HUD shows debug buttons for:

- reveal first alien now
- reveal all aliens
- skip to active round
- force wrong accusation penalty
- spawn chase test alien
- print current aggression multipliers

Recommended debug tuning loop:

1. Set `Enabled = true`.
2. Start Studio Play.
3. Press `Skip Active`.
4. Press `Chase Test`.
5. Adjust chase/attack values in `Config.lua`.
6. Stop Play, let Rojo resync, and retest.
7. Set `Enabled = false` before normal playtests.

## MVP Scope

Keep the MVP simple:

- server owns all game truth
- client never receives secret alien identities until reveal
- no monetization yet
- no data saving yet
- no advanced UI yet
- small modular services over giant scripts
