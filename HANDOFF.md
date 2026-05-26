# Chicken Alien Hunt Handoff

Date: 2026-05-26

## Project Summary

Chicken Alien Hunt is a Roblox Rojo MVP for a multiplayer mystery-horror social deduction game.

Players enter a strange farm town where normal-looking NPCs may secretly be Galloid aliens. The game loop is investigation first, combat second:

1. Players wait for the round.
2. FarmTown spawns.
3. NPCs and clue props spawn.
4. The server secretly chooses aliens.
5. Players inspect clues and watch NPC behavior.
6. Players accuse suspicious NPCs.
7. Correct accusations reveal aliens.
8. Revealed aliens chase and attack players.
9. Players win by eliminating all aliens.
10. Aliens win if time expires or all spawned player characters are down.

The server owns all game truth. Clients never receive secret alien identities until the server reveals them.

## Files Added

- `README.md`
  - Windows setup instructions.
  - Rojo/Studio run steps.
  - Studio testing guide.
  - Debug testing notes.

- `MAP_DESIGN.md`
  - FarmTown story shape.
  - Map zone purposes.
  - Clue logic.
  - Player fantasy.
  - Future alien direction.

- `HANDOFF.md`
  - This summary of what has been built and what should come next.

- `src/server/MapEventService.lua`
  - Server-owned map/radio/scanner pings during active rounds.

- `src/server/PlayerPingService.lua`
  - Server-validated player callouts and temporary world ping markers.

- `src/server/DebugService.lua`
  - Disabled-by-default Studio balancing commands for fast MVP tuning.

## Tooling Changes

Updated `rokit.toml`:

- Added pinned Rojo CLI:
  - `rojo = "rojo-rbx/rojo@7.5.1"`

This makes Windows setup cleaner with:

```powershell
rokit install
```

## Map Work

FarmTown now has clearer design intent.

`src/shared/MapLayout.lua` now includes `MapLayout.ZoneRoles` metadata for:

- SouthernEntry
- TownWell
- GeneralStore
- Barn
- FeedSilo
- ChickenCoop
- ObservationPole
- AbandonedTruck

The map still builds through `MapService` as before, but landmarks now have explicit gameplay roles for future systems.

Current FarmTown landmarks:

- General Store
- Barn
- Feed Silo
- Town Well
- Chicken Coop
- Broken Windmill
- Observation Pole
- Abandoned Truck
- Fences, warning posts, and sickly lights

## Alien Design Work

`src/shared/Config.lua` now includes future-facing alien definitions.

Current runtime enemy:

- `Galloid`

Future disabled factions:

- `Husker`
- `Hollowman`
- `Crawler`
- `Choir`

Future disabled Galloid profiles:

- `GalloidPecker`
  - Aggressive breach variant.
  - Intended to pressure combat.

- `GalloidBrooder`
  - Cluster/infiltration variant.
  - Intended to hide near NPC groups.

- `GalloidMolt`
  - Evidence-heavy variant.
  - Intended to leave more trace clues.

- `GalloidRooster`
  - Alarm/pressure variant.
  - Intended to create louder round pressure.

These profiles are config-only for now. Runtime still selects base `Galloid`.

## Gameplay Added

### Revealed Alien Health Bars

`NPCService` now creates a server-owned world health bar above revealed aliens.

Behavior:

- appears when an alien is revealed
- updates after damage
- changes color as health drops
- changes to a down state when eliminated

### Map Event Pings

`MapEventService` broadcasts atmospheric active-round pings through the existing mission warning HUD channel.

Examples:

- Barn radio static.
- Chicken coop clucking.
- Silo broken speech.
- Town well scanner ping.
- Observation pole motion ping.
- General store ledger ping.

These pings point players toward map zones but do not reveal alien identities.

### Player Ping System

`PlayerPingService` adds three HUD ping buttons:

- `Suspicious`
- `Clue`
- `Help`

Server validation:

- pings only work during active rounds
- ping type must be known
- player must have a character root
- cooldown prevents spam

Successful pings:

- broadcast a `TEAM PING` HUD message
- create a temporary colored world marker at the player's position

### Revealed Alien Chase

`AlienService` now moves revealed aliens toward the nearest living player.

Config:

```lua
Config.RevealedAlienChase = {
	Enabled = true,
	Range = 62,
	StopDistance = 9,
	Speed = 10.5,
	LeashDistance = 76,
	WarningCooldown = 7,
	StartWarning = "CHASE WARNING: confirmed entity has locked onto you.",
	StopWarning = "CHASE UPDATE: entity pursuit signal dropped.",
	ScreenPulseDuration = 0.75
}
```

Behavior:

- only revealed, non-eliminated aliens chase
- stunned aliens pause chase
- aliens stop near attack distance
- final stop distance value is `9`
- chase-start warning is sent to the targeted player
- chase-stop warning is sent when pursuit drops
- chased player receives a short screen pulse
- wrong accusations temporarily increase chase speed and range
- existing attack logic still handles damage

This is simple direct movement, not pathfinding.

### Wrong Accusation Pressure

Wrong accusations now increase tension in several small server-owned ways:

- reduce remaining round time
- boost revealed alien attack aggression
- boost revealed alien chase aggression
- broadcast emergency HUD warning
- trigger short alarm/map event pulse
- trigger a short screen pulse on clients

### NPC Ambient Behavior

NPCs now have lightweight ambient behavior during active rounds:

- occasional idle rotation
- small wandering movement between nearby NPC spawn points
- short random pauses
- occasional clustering near authored map landmarks

This is still simple anchored-model movement, not pathfinding.

## Debug Testing Added

`Config.DebugTesting` is disabled by default.

```lua
Config.DebugTesting = {
	Enabled = false,
	ControlsEnabled = true,
	CommandCooldown = 0.5,
	MinPlayersOverride = 1,
	IntermissionLength = 3,
	RoundLength = 90,
	ResultsLength = 6,
	RevealFirstAlienAfter = nil,
	ChaseTestSpawnDistance = 24
}
```

When enabled, `RoundService` can:

- override minimum players
- shorten intermission
- shorten active rounds
- shorten results
- schedule a first-alien reveal after round start

`AlienService.DebugRevealFirstAlien()` uses the normal server reveal path, so even debug reveal does not leak identities directly to the client before reveal.

When debug testing and controls are enabled, the client shows compact debug buttons:

- Reveal first alien now.
- Reveal all aliens.
- Skip to active round.
- Force wrong accusation penalty.
- Spawn chase test alien.
- Print current attack/chase aggression multipliers.

## README Testing Guide Added

`README.md` now includes:

- Windows setup.
- Studio run steps.
- Single-player smoke test.
- Accusation and combat test.
- Player ping test.
- Class ability test.
- Local multiplayer test.
- Failure checks.
- Debug testing instructions.

## Current Services

Server services:

- `RemoteService`
- `MapService`
- `MapEventService`
- `PlayerService`
- `PlayerPingService`
- `DebugService`
- `NPCService`
- `AlienService`
- `ClueService`
- `AccusationService`
- `CombatService`
- `ClassAbilityService`
- `ResultService`
- `RoundService`

Client:

- `src/client/Main.client.lua`
  - mission HUD
  - class selection
  - ability button
  - ping buttons
  - debug buttons when `Config.DebugTesting.Enabled` and `ControlsEnabled` are true
  - clue/suspect display
  - combat and accusation feedback
  - audio hooks

Shared:

- `Config.lua`
- `MapLayout.lua`

## Validation Run

Linux-safe validation used:

```bash
rojo sourcemap default.project.json
rojo build default.project.json --output /tmp/chicken-alien-hunt.rbxlx
luau src/shared/Config.lua
```

These pass after the latest changes.

Directly running server/client files with `luau` is limited outside Roblox because they depend on Roblox globals such as:

- `game`
- `Instance`
- `Color3`
- `Vector3`
- `CFrame`

Studio playtesting is still required for movement feel, UI layout, prompts, tool activation, and replication.

## Studio-Tested Observations

No Studio playtest has been run in this Linux environment.

Known untested areas:

- chase speed and stop distance feel
- attack cooldown feel
- HUD readability with debug controls enabled
- screen pulse intensity
- alarm pulse readability
- NPC clustering frequency
- local multiplayer replication feel

## Known Testing Needs

When someone can test on Windows in Roblox Studio, verify:

1. FarmTown spawns correctly.
2. HUD fits after adding ping buttons.
3. Clue inspection still updates evidence and suspects.
4. Accusations still reveal only real aliens.
5. Revealed alien health bars appear and update.
6. Revealed aliens chase living players at a reasonable speed.
7. Stun pauses chase.
8. Player pings create markers and respect cooldown.
9. Map event pings appear during active rounds.
10. Debug testing can shorten loops and reveal one alien when enabled.
11. Debug testing is off for normal testing.
12. Debug buttons work only when debug testing is enabled.
13. Debug `SpawnChaseTestAlien` places a revealed alien at a useful distance.

## Recommended Next Sprint

Best next sprint: Studio balancing pass.

Suggested tasks:

1. Tune `Config.RevealedAlienChase.Speed`, `Range`, and `StopDistance`.
2. Tune `Config.RevealedAlienAttack.Cooldown`.
3. Tune `Config.WrongAccusation.TimePenalty`, `AggressionMultiplier`, and `ChaseAggressionMultiplier`.
4. Tune screen pulse intensity and duration.
5. Improve HUD layout if ping/debug buttons crowd the panel.
6. Add basic pathing later only if direct chase feels too awkward.

Do not add monetization, data saving, advanced UI, or multiple maps yet.
