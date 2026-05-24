# Architecture

This is a Rojo-based Roblox project.

## Folder Layout

src/server
Server-only scripts and ModuleScripts.

src/client
Client-only scripts and LocalScripts.

src/shared
Shared ModuleScripts used by both server and client.

## Server Responsibilities

The server owns all game truth.

Server controls:
- round state
- timers
- NPC spawning
- alien identity
- clue truth
- accusations
- damage
- win/loss state
- rewards

Never trust the client for critical gameplay decisions.

## Client Responsibilities

Client controls:
- UI
- sounds
- camera effects
- local prompts
- visual feedback
- input requests

Client may request actions, but server validates them.

## Module Style

Prefer small focused services.

Use ModuleScripts for:
- RoundService
- NPCService
- AlienService
- ClueService
- AccusationService
- ResultService

Each service should expose:
- Init()
- Start()
- public methods needed by other services

Avoid:
- giant scripts
- duplicated state
- client-authoritative logic
- hardcoded logic spread everywhere

## Initial Services

RoundService:
Controls intermission, active round, ending, and timer.

NPCService:
Creates and tracks NPCs.

AlienService:
Selects secret aliens and handles reveal state.

ClueService:
Generates clues based on alien data.

AccusationService:
Handles player accusations and validates guesses.

ResultService:
Checks win/loss conditions.