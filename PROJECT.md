# Chicken Alien Hunt

A Roblox multiplayer mystery-horror social deduction game.

Players are deployed into strange locations where normal-looking NPCs may secretly be disguised alien entities. The first enemy faction is the Galloid species: strange chicken-like aliens who disguise themselves as humans.

The game should feel funny, creepy, paranoid, and replayable.

## Core Pillars

- Mystery before combat
- Suspicion and investigation
- Strange alien behavior
- Teamwork under pressure
- Stylized horror-comedy
- Replayable missions
- Server-authoritative gameplay

## Core Gameplay Loop

1. Players wait in lobby.
2. Mission starts.
3. Players enter a map.
4. NPCs spawn.
5. Some NPCs are secretly aliens.
6. Players investigate suspicious behavior.
7. Clues appear over time.
8. Players accuse or scan suspects.
9. Correct accusations reveal aliens.
10. Revealed aliens attack or try to escape.
11. Players win by eliminating aliens and saving civilians.

## Player Classes

### Hunter
Combat specialist. Strong against revealed aliens.

### Investigator
Finds clues faster and detects suspicious NPC behavior.

### Engineer
Places cameras, traps, sensors, and repairs systems.

### Medic
Heals players, slows infection, and supports survival.

### Scout
Fast explorer who tracks movement and marks suspects.

## Alien Factions

### Galloids
Chicken-like alien infiltrators. Main MVP enemy.

Traits:
- clucking sounds
- strange head twitching
- corn obsession
- feather residue
- awkward human behavior
- creepy fake smiles

### Huskers
Parasite aliens. Future enemy type.

### Hollowmen
Almost-perfect human mimics. Future enemy type.

### Crawlers
Stealth predator aliens. Future enemy type.

### Choir
Psychological alien entity. Future nightmare-tier enemy.

## MVP Scope

Build only the first playable version.

MVP includes:
- one placeholder map
- round timer
- NPC spawning
- hidden Galloid assignment
- simple clue generation
- accusation mechanic
- alien reveal
- basic alien attack behavior
- win/loss logic

Do not build yet:
- full progression
- monetization
- complex UI
- multiple maps
- boss aliens
- advanced animations
- data saving

## Current Build Target

Build the MVP services in this order:

1. RoundService
2. NPCService
3. AlienService
4. ClueService
5. AccusationService
6. ResultService