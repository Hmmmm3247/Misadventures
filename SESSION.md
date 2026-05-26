# Chicken Alien Hunt Session Handoff

## Project Snapshot

Chicken Alien Hunt is a Rojo-based Roblox MVP for a multiplayer mystery-horror social deduction game.

The current build is a simple playable vertical slice:

1. Players join and wait through intermission.
2. A farm-town test map is generated.
3. NPCs spawn.
4. The server secretly chooses Galloid aliens.
5. Players inspect clues.
6. Clues narrow the public suspect list without revealing secret identities.
7. Players accuse NPCs.
8. Correct accusations reveal aliens.
9. Revealed aliens become dangerous.
10. Players use a basic combat tool to eliminate revealed aliens.
11. Players win by eliminating all aliens.
12. Aliens win if time expires or all player characters are down.

The server owns round state, alien identity, clue truth, accusation validation, combat damage, player health checks, and win/loss outcomes.

## Latest Changes

- Added `README.md` with Windows setup, Rojo run steps, Studio connection steps, quick test notes, validation commands, and MVP scope reminders.
- Added `rojo` to `rokit.toml` so Windows setup can install the pinned Rojo CLI with `rokit install`.
- Added a simple server-created world health bar for revealed aliens in `NPCService`.
- Revealed alien health bars update after damage and switch to a down state when eliminated.
- Added `MAP_DESIGN.md` with FarmTown zones, story shape, player fantasy, clue logic, and future alien direction.
- Added non-runtime alien type/profile definitions in `Config.lua` for future Galloid variants and later factions.
- Added `MapLayout.ZoneRoles` and zone metadata so FarmTown landmarks have explicit gameplay jobs.
- Added `MapEventService` for server-owned active-round radio/scanner/audio map pings that point players toward zones without revealing alien identities.
- Added `PlayerPingService`, `PlacePing`, and three simple HUD pings: Suspicious, Clue, and Help.
- Added simple server-owned revealed-alien chase movement controlled by `Config.RevealedAlienChase`.
- Added disabled-by-default `Config.DebugTesting` for shorter Studio test loops and optional server-side first-alien reveal.

## Source Layout

- `default.project.json`: Rojo DataModel mapping.
- `src/server`: server-only scripts and ModuleScripts.
- `src/client`: client-only LocalScripts.
- `src/shared`: shared ModuleScripts used by both server and client.

Rojo currently maps:

- `src/shared` to `ReplicatedStorage.Shared`
- `src/server` to `ServerScriptService.Server`
- `src/client` to `StarterPlayer.StarterPlayerScripts.Client`

## Core Services

- `Main.server.lua`: bootstraps all server services in a fixed order.
- `RemoteService.lua`: creates and owns all remotes under `ReplicatedStorage.ChickenAlienHuntRemotes`.
- `MapService.lua`: builds the generated/authored test arena under `Workspace.ChickenAlienHunt`.
- `MapEventService.lua`: broadcasts active-round FarmTown map pings from configured zones.
- `PlayerService.lua`: assigns MVP classes, applies health/speed stats, and sends safe player snapshots to the HUD.
- `PlayerPingService.lua`: validates player callouts and creates temporary world ping markers.
- `NPCService.lua`: spawns simple physical NPC models, tracks public NPC state, and owns accuse prompts.
- `AlienService.lua`: secretly selects aliens, stores private alien records, reveals aliens, handles alien attacks, tracks alien health, and marks eliminations.
- `ClueService.lua`: spawns clue objects, handles clue inspection, tracks discovered traits, and builds suspect snapshots.
- `AccusationService.lua`: validates accusation requests and reveals correct aliens.
- `CombatService.lua`: creates the `Alien Zapper` Tool and validates player attacks against revealed aliens.
- `ClassAbilityService.lua`: owns one MVP active ability per class with server validation and cooldowns.
- `ResultService.lua`: records accusations and resolves round outcomes.
- `RoundService.lua`: runs waiting, intermission, active round, and results states.

## Shared Config

`src/shared/Config.lua` currently contains:

- Debug testing knobs:
  - faster intermission/round/results timings
  - minimum player override
  - optional first alien reveal after active round start
- Round timing:
  - intermission
  - active round length
  - results duration
  - tick interval
- NPC and alien counts.
- Prompt distances and hold times.
- Debug helpers:
  - `DebugPrintSecretAliens`
  - `RandomSeed`
- Player stats:
  - base health
  - base walk speed
  - class assignment order
- Combat tuning:
  - tool name
  - range
  - damage
  - cooldown
- NPC behavior tuning:
  - idle tick interval
  - move speed
  - move chance
  - idle pause range
  - random facing chance
- Alien behavior tuning:
  - tell chance
  - player notice range
  - light avoidance chance
  - stare/freeze/twitch durations
- Suspicion event tuning:
  - notice chance
  - warning cooldown
  - creepy HUD messages
- Wrong accusation tuning:
  - time penalty
  - aggression duration
  - aggression multiplier
  - mission warning text
- Class ability tuning:
  - ability names
  - ranges
  - durations
  - cooldowns
- Revealed alien attack tuning:
  - alien health
  - range
  - damage
  - cooldown
  - tick interval
- Trait definitions.
- Alien trait profile.
- Decoy trait sets.
- Clue definitions.
- Audio config.
- MVP class definitions.

## Map And Presentation

`src/shared/MapLayout.lua` defines the current authored test arena:

- Ground size/color/material.
- Horror lighting:
  - night time
  - fog
  - atmosphere
  - color correction
  - bloom
  - depth of field
- Player spawns.
- NPC spawns.
- Clue spawns.
- Simple farm-town props:
  - general store
  - barn
  - feed silo
  - well
  - chicken coop
  - broken windmill
  - observation pole
  - abandoned truck
- Fences, warning posts, and sickly light sources.

`MapService` can fall back to generated spawns if authored layout data is missing.

## Gameplay Implemented

### Round Flow

- Waits for minimum players.
- Runs intermission.
- Starts an active round.
- Spawns NPCs and clues.
- Selects hidden aliens.
- Broadcasts public snapshots.
- Ends in results.

### NPCs

- NPCs are simple server-created models.
- NPCs have names from config.
- NPCs can be accused through `ProximityPrompt`.
- Unrevealed NPCs lightly wander between nearby NPC spawn points during active rounds.
- Unrevealed NPCs randomly pause and face different directions.
- Revealed aliens get a bright alien visual treatment.
- Eliminated aliens are visually darkened/disabled.

### Alien Identity

- Alien identities are selected server-side only.
- Clients do not receive alien identities until the server reveals an NPC.
- Full-profile decoys exist so clue matching does not directly expose exact aliens.

### Clues And Suspects

- Clues are physical inspectable props.
- Clue text and trait hints are only public after discovery.
- Discovered traits generate a public suspect snapshot.
- HUD shows discovered evidence and suspects matching discovered traits.

### Accusations

- Accusations are server-validated.
- Accusations only work during active rounds.
- Cooldown prevents spam.
- Already revealed NPCs cannot be accused again.
- Correct accusation reveals an alien.
- Wrong accusation sends risk feedback based on clue match count.
- Wrong accusation also reduces the active timer, boosts alien aggression temporarily, and broadcasts a mission warning.

### Behavior Tells

- Hidden aliens intermittently perform suspicious behavior.
- Tells include:
  - long staring near players
  - freezing briefly
  - twitch/jitter moments
  - avoiding nearby light sources
- Nearby players may receive a generic `BEHAVIOR FLAG` warning.
- Suspicion warnings never reveal the exact alien identity.

### Combat

- `CombatService` creates a basic `Alien Zapper` Tool.
- Tool attacks are server-authoritative.
- Attacks only damage revealed, non-eliminated aliens.
- Server validates:
  - round is active
  - cooldown
  - nearby revealed alien exists
  - target is not eliminated
- Hunter currently deals bonus combat damage.
- Alien health and elimination state are server-owned.
- Revealed aliens now display a simple replicated world health bar above the NPC model.

### Alien Attacks

- Revealed aliens damage nearby living players on the server.
- Revealed aliens now move toward the nearest living player within chase range.
- Wrong accusations temporarily reduce revealed-alien attack cooldown through an aggression multiplier.
- Eliminated aliens stop attacking.
- If all spawned player characters are down, aliens win.

### Player Classes

Current class support is intentionally simple.

- Classes can be chosen from the HUD class panel.
- Classes are also assigned automatically in this order before a player chooses:
  - Hunter
  - Investigator
  - Medic
  - Scout
  - Engineer
- Hunter:
  - bonus damage against revealed aliens
  - active ability stuns the nearest revealed alien in range
- Medic:
  - higher max health
  - active ability heals the most injured nearby living player, including self
- Scout:
  - faster walk speed
  - active ability marks the nearest NPC with a temporary highlight
- Investigator:
  - active ability scans the nearest unrevealed NPC and reports discovered-clue match count
- Engineer:
  - active ability places a temporary sensor that stuns revealed aliens near it

These are first-pass MVP abilities, not polished class kits.

### HUD And Audio

`src/client/Main.client.lua` creates a minimal HUD showing:

- Round state.
- Timer.
- Aliens found count.
- Player class.
- Player health.
- Class selection buttons.
- Class ability button.
- Class ability cooldown countdown.
- Revealed alien health line.
- Weapon cooldown readout for `Alien Zapper`.
- Cold mission-terminal wording for round, combat, accusation, and result feedback.
- Temporary world highlights for weapon hits, heals, scans, stuns, and marks.
- Brighter Engineer sensor object with a visible radius disc.
- Discovered evidence.
- Suspects matching discovered evidence.
- Accusation feedback.
- Combat feedback.
- Round results.

Client-side audio includes:

- ambient drone
- clue stinger
- wrong accusation sound
- alien reveal sound
- win/loss sounds
- random environmental pulses

All audio settings live in `Config.Audio`.

## Current Remotes

Created by `RemoteService` under `ReplicatedStorage.ChickenAlienHuntRemotes`:

- `RoundState`
- `NPCSnapshot`
- `ClueSnapshot`
- `ClueDiscovered`
- `SuspectSnapshot`
- `NPCRevealed`
- `AccusationResult`
- `CombatResult`
- `PlayerSnapshot`
- `MissionWarning`
- `RoundResults`
- `AccuseNPC`
- `SelectClass`
- `UseClassAbility`

The current `Alien Zapper` combat path uses a server-created Tool activation, not a client RemoteFunction.

## How To Run Later

Windows setup is now documented in `README.md`.

Install tools:

```bash
rokit install
```

Start Rojo:

```bash
cd ~/chicken-alien-hunt
rojo serve
```

Then open Roblox Studio and connect with the Rojo plugin.

## Studio Test Checklist

1. Start `rojo serve`.
2. Connect Roblox Studio through the Rojo plugin.
3. Press Play.
4. Confirm the HUD appears.
5. Confirm class and health appear in the HUD.
6. Wait through intermission.
7. Confirm the farm-town arena appears.
8. Confirm NPCs spawn.
9. Confirm clue props spawn.
10. Watch unrevealed NPCs for light wandering, pauses, and random facing.
11. Stand near groups of NPCs and wait for possible `BEHAVIOR FLAG` suspicion warnings.
12. Confirm suspicion warnings do not name the alien.
13. Inspect clue props with `Inspect Clue`.
14. Confirm discovered clue hints appear in the HUD.
15. Confirm suspect list updates after clues.
16. Accuse NPCs through `Accuse` prompts.
17. Confirm wrong accusations show feedback, reduce the timer, and broadcast the aggression warning.
18. Confirm correct accusations reveal aliens.
19. Equip/use `Alien Zapper` near a revealed alien.
20. Confirm combat feedback appears and a short red hit highlight flashes on the revealed alien.
21. Confirm revealed alien health appears in the HUD and decreases after hits.
22. Confirm eliminated aliens darken/disable.
23. Confirm all eliminated aliens triggers a player win.
24. Let time expire and confirm alien win.
25. Let revealed aliens down all spawned player characters and confirm alien win.
26. Test with multiple players if possible:
   - first player should be Hunter
   - second should be Investigator
   - third should be Medic
   - fourth should be Scout
   - fifth should be Engineer
27. Confirm Hunter does more damage than non-Hunter.
28. Confirm Medic has more health.
29. Confirm Scout moves faster.
30. Use the class selection buttons and confirm class changes update the HUD.
31. Select Medic, take damage, press `Use Class Ability`, and confirm healing feedback plus a green player highlight.
32. Select Investigator, stand near an unrevealed NPC, press `Use Class Ability`, and confirm scanner feedback plus a yellow NPC highlight without revealing secret identity.
33. Select Engineer, press `Use Class Ability`, and confirm a blue sensor and faint radius disc appear.
34. Select Scout, stand near an NPC, press `Use Class Ability`, and confirm the NPC is highlighted.
35. Select Hunter, reveal an alien, press `Use Class Ability`, and confirm stun feedback.
36. Confirm the ability button shows a cooldown countdown after successful ability use.
37. Confirm ability cooldown spam is blocked.
38. Use `Alien Zapper` repeatedly and confirm weapon cooldown feedback appears.
39. Confirm combat and accusation feedback uses the mission-terminal wording clearly.
40. Confirm audio cues play.

## Validation Done

Latest local validation:

```bash
rojo build default.project.json --output /tmp/chicken-alien-hunt.rbxlx
rojo sourcemap default.project.json
luau src/shared/Config.lua
```

These passed.

Note: the installed `luau` binary does not support `--check`. Running server/client files directly outside Roblox fails on expected Roblox globals like `game`, `Instance`, `Color3`, and `Vector3`, so full behavior validation still needs Studio. `luau src/server/NPCService.lua` currently parses and then fails at runtime on `game:GetService`, which is expected outside Roblox.

## Missing Or Not Built Yet

### High Priority

- Class abilities are first-pass only and need Studio tuning.
- Studio-test the new revealed-alien world health bar.
- A better accusation testing path:
  - debug accuse UI
  - nearby NPC list
  - optional secret alien print for local testing

### Gameplay Gaps

- Revealed aliens do not chase or pathfind yet.
- NPC wandering is lightweight spawn-to-spawn movement, not pathfinding.
- No civilian rescue mechanics yet.
- No player revive/downed-state system beyond Roblox humanoid health.
- No weapon variety.
- No enemy attack animation.
- No proper alien escape behavior.
- Correct accusations do not add bonuses or pressure yet.

### Class Gaps

- No polished lobby/class selection flow.
- Medic heal has a temporary target highlight but needs balance tuning.
- Investigator scanner has a temporary highlight but needs better UI presentation.
- Engineer sensor is a simple static stun sensor with a visible radius, not a full trap system.
- Scout mark is a temporary highlight, not true tracking.
- Hunter stun has a temporary highlight but needs sound/animation polish.

### UI Gaps

- HUD is functional but still basic.
- No proper suspect board.
- Class select exists only as a simple HUD panel.
- No health bars over revealed aliens.
- No combat reticle or target indicator.
- No mobile-specific control polish.
- No settings/menu UI.

### Content Gaps

- Only one authored placeholder map.
- Only Galloid aliens exist.
- No multiple alien factions.
- NPC bodies are simple parts, not proper rigs.
- No authored animations.
- Built-in placeholder sound IDs should eventually be replaced with owned Roblox audio assets.
- No custom icons or polished visual assets.

### Technical Gaps

- No automated Roblox test runner yet.
- No `luau-analyze` setup yet.
- No CI.
- No persistent data by design for MVP.
- No monetization by design for MVP.
- No analytics or telemetry.
- No anti-exploit hardening beyond current server validation.

## Suggested Next Sprint

Best next task: Studio-tune the class abilities, combat feedback, and revealed-alien health bars.

Recommended next implementation:

1. Tune NPC wandering and alien tell frequencies in Studio.
2. Add revealed-alien chase movement after static behavior is stable.
3. Add a better accusation testing path for local MVP iteration.
4. Add suspect board polish.
5. Add sound/animation polish for ability feedback.
