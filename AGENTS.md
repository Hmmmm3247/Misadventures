# Codex Instructions

Always read PROJECT.md and ARCHITECTURE.md before making changes.

This is a Roblox Rojo project for Chicken Alien Hunt.

## Development Rules

- Keep the MVP simple.
- Do not overbuild.
- Do not add monetization yet.
- Do not add data saving yet.
- Do not add advanced UI yet.
- Server must own all game truth.
- Client must never know secret alien identities unless revealed.
- Keep services modular.
- Prefer clean ModuleScripts.
- Avoid giant scripts.

## Current Priority

Build the MVP service skeleton first:

- RoundService
- NPCService
- AlienService
- ClueService
- AccusationService
- ResultService

Each service should be simple, readable, and easy to expand.

## Validation

After changes:
- make sure Lua syntax is valid
- make sure Rojo paths still match default.project.json
- do not break existing src/server, src/client, src/shared layout