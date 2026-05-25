# FarmTown Map Design

FarmTown is the MVP investigation map. It should feel like a small rural settlement that was normal earlier in the day and wrong by midnight.

The map is not a large open world. It is a compact arena built for repeated short rounds where players can quickly learn landmark locations, split up, regroup, and compare suspicious behavior.

## Story Shape

Players are emergency containment contractors sent to a quarantined farm town after residents reported missing people, strange clucking from locked buildings, and townsfolk acting almost human.

The first playable threat is the Galloid: a chicken-like alien species wearing a human disguise. Galloids are funny at a distance and unsettling up close. They stare too long, avoid mirrors and light, smell faintly of corn, repeat phrases badly, and gather near farm supplies.

The round should escalate in three beats:

1. Investigation: players read the town, inspect clues, and watch NPC movement.
2. Suspicion: clues and behavior tells narrow the suspect list.
3. Breach: correct accusations reveal aliens, turning the round into a short survival fight.

## Player Fantasy

Players are not superheroes. They look and play like field operatives with improvised containment gear.

- Hunter: front-line responder with better damage against revealed aliens.
- Investigator: evidence reader who turns weak clues into stronger suspect confidence.
- Engineer: tool user who places sensors and eventually cameras or traps.
- Medic: support responder who keeps the team alive.
- Scout: fast spotter who follows suspicious movement and marks targets.

Combat should be useful but not the first answer. Players need evidence before they can safely reveal the real threats.

## Current FarmTown Zones

### Southern Entry

Player spawn area near the broken windmill approach.

Purpose:
- gives players a consistent start point
- gives the HUD and tools time to load
- points players toward the town center

Gameplay:
- low threat
- good place for intermission-to-round orientation
- future location for mission board or class staging

### Town Well

Central landmark and visual anchor.

Purpose:
- helps players navigate
- acts as the regroup point
- creates a clear midpoint between the store, barn, silo, and coop

Gameplay:
- current sickly light source
- useful place for players to compare clues
- future candidate for scanner pulse, team objective, or extraction marker

### General Store

Western investigation landmark.

Purpose:
- holds the ledger clue theme
- implies NPC routines and fake civilian behavior
- supports social deduction by making players ask who has been acting normal

Gameplay:
- clue type: ledger / strange purchasing behavior
- trait supported: light avoidance through suspicious store behavior
- future: alibi board, receipt clues, locked back room

### Barn

Eastern high-risk Galloid landmark.

Purpose:
- farm supply location tied to corn residue
- natural place for aliens to drift toward
- strong visual silhouette for navigation

Gameplay:
- clue type: corn crate
- trait supported: corn residue
- future: louder alien tells, ambush spot after reveal, chase loop around barn

### Feed Silo

North-east industrial landmark.

Purpose:
- vertical object that breaks up sightlines
- supports radio/static clue staging
- gives revealed aliens cover during combat

Gameplay:
- clue type: radio
- trait supported: strange speech
- future: timed radio transmission, map-wide warning, objective repair point

### Chicken Coop

South-west horror-comedy landmark.

Purpose:
- strongest Galloid flavor point
- makes the map premise readable
- provides a suspicious but not automatically correct location

Gameplay:
- current NPC spawn pressure nearby
- future clue type: feathers, scratch marks, clucking audio
- future alien behavior: hidden Galloids linger nearby more often

### Observation Pole

Northern lookout landmark.

Purpose:
- supports the "watch behavior" part of the game
- gives Scout and Investigator a natural job location
- makes suspicious movement easier to stage

Gameplay:
- clue type: watch post
- trait supported: does not blink
- future: temporary high-visibility scan or motion ping

### Abandoned Truck

Western edge landmark and cover object.

Purpose:
- breaks the outer lane
- suggests failed evacuation
- gives combat a rough obstacle

Gameplay:
- current cover/route marker
- future clue type: torn seat, abandoned supplies, failed escape record

## Clue Logic

Clues should not name an alien. They should reveal traits that narrow suspects.

Current trait clues:

- Mirror: target avoids mirrors.
- Corn crate: target smells faintly of corn.
- Watch post: target stares too long.
- Radio: target repeats phrases incorrectly.
- Ledger: target enters stores but never buys anything.

The suspect list should feel helpful but imperfect. Full-profile decoy NPCs are intentional: a perfect clue match should create confidence, not certainty.

## Alien Variants

The MVP runtime still uses the base Galloid. Variant definitions exist for tuning and future behavior wiring.

### Galloid Pecker

Aggressive breach variant.

- dangerous after reveal
- shorter attack cooldown
- should force players to kite or stun

### Galloid Brooder

Cluster/infiltration variant.

- prefers NPC-heavy areas
- harder to isolate from decoys
- should pressure players to observe groups

### Galloid Molt

Evidence-heavy variant.

- leaves feather/corn-style clues
- easier to track, but may lead players into false confidence

### Galloid Rooster

Alarm/pressure variant.

- louder tells
- boosts panic or aggression after wrong accusations
- future candidate for map-wide cluck warnings

## Future Alien Factions

These are not MVP implementation targets yet.

- Husker: parasite that weakens or infects players over time.
- Hollowman: nearly perfect mimic that produces fewer obvious tells.
- Crawler: stealth predator that avoids crowds and attacks isolated players.
- Choir: psychological threat that distorts UI, audio, and certainty.

## Next Map Goals

Keep the map simple, but give every landmark a job:

1. Add one clue or behavior reason per major landmark.
2. Give revealed aliens simple chase routes around barn, silo, well, and truck.
3. Add local audio tells near chicken coop and silo.
4. Add a debug-friendly way to understand NPC spawn and clue spawn coverage.
5. Avoid adding new maps until FarmTown is fun for several repeated rounds.
