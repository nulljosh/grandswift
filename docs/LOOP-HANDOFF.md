# Vancouver Vice loop handoff (2026-09-23, evening)

## What the loop is

Driving Unreal 5.8 headless to build Vancouver Vice Act Two as a vertical slice: polish the first five minutes (Apple Store heist, car jack, escape) to shipping quality, package the macOS .app, and QA against real hardware before wide release. One subagent per step (Haiku for mechanical tasks, Sonnet for architecture), Opus for hard decisions only. Restart from the task queue if session ends.

## Where things stand

Editor 8-10 GB (near-player tile loading fixed the 54 GB hog). Skin fixed (textures synthesized, tone 0.10 from 0.85). Male body built and repointed to saved Joshua assets; Body/Face/glasses applied. Camera bugs fixed but run stalled: player is SpectatorPawn_0 instead of character, photo booth fails. doctor.sh monitors health (footprint, lean mode). Leaner city via SSE 12. Mission two on car jack. Act two live in browser. 5 hours yesterday burned on usage lockout, cold boots, Ollama hog, camera stack. Next session starts with pawn fix. 2026-09-23: Character fix pass in progress (red skin tone, male body foundation committed, polo shoulder seams pending, city detail SSE 8 pass running headless). Subagent halted at 90% usage; restart at male body refit (next in queue).

## Next, in order

0. Fix the pawn — check GameMode default pawn and PlayerStart in Lvl_ThirdPerson, run qa.py shot to get street photo, swap into README
1. Male body polish — polo fits badly (refit), check weight painting and bone hierarchy
2. Walls and camera collision — walk through interiors (inside-out camera fix), third-person clip check
3. Map detail SSE 6 and daylight — day/night flashing, shader bump, Gastown perf test
4. Splash preload screen — loading spinner while tiles stream
5. Apple Store launcher with chasers — press Tab/mouse to jack car, cops start pursuit
6. Drive PASS and video — playtest car physics, record slice demo
7. BP_Heat stars and system — three stars, wanted meter, crime heat
8. Guns and firing — Shift aim, mouse click fire, casings and audio
9. NPCs and dynamic crowd — NPCs, dialogue, mission feedback
10. Headless QA mode — autoplay.dsl unattended, crash logs, fail fast
11. Package the .app — build macOS binary, sign, notarize, ship

## Restart prompt

```
/loop 1h Vancouver Vice, today's goal: Unreal memory leans at 8-10 GB, male body fitted, mission two on the car jack, nearest task in the queue next. One Haiku subagent per step, mechanical work only; Sonnet for architecture decisions. Start with male body refit (polo shoulder seams), then walls+collision, then map detail/daylight. Next roadmap milestone: vertical slice packaged and QA'd on real Mac. If blocked or decision point: stop the loop, post findings, wait for guidance.
```
