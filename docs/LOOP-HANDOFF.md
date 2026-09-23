# Vancouver Vice loop handoff (2026-09-23, evening)

## What the loop is

Driving Unreal 5.8 headless to build Vancouver Vice Act Two as a vertical slice: polish the first five minutes (Apple Store heist, car jack, escape) to shipping quality, package the macOS .app, and QA against real hardware before wide release. One subagent per step (Haiku for mechanical tasks, Sonnet for architecture), Opus for hard decisions only. Restart from the task queue if session ends.

## Where things stand

Editor runs 8-10 GB with near-player tile loading fixed (was 54 GB due to abandoned Play session). Black polo is fitted to Joshua but needs male body refit to fit right. Fitted glasses placed from face head bone. Mission two (car jack and escape) wired and working. doctor.sh monitors editor health. Leaner city rendering via SSE 12. Act two missions live in browser. Package.sh and autoplay.dsl drafted for vertical-slice milestone. Loop handoff written. Landing simplified, roadmap caught up. Docs at 100%, Apache 2.0. CI green. 2026-09-23: Character fix pass in progress (red skin tone, male body foundation committed, polo shoulder seams pending, city detail SSE 8 pass running headless). Subagent halted at 90% usage; restart at male body refit (next in queue).

## Next, in order

1. Male body refit — polo fits badly on female model; swap to male body, adjust weights, refit polo shoulder-seam
2. Walls and camera collision — walk through buildings (currently inside-out camera), fix third-person view clipping
3. Map detail SSE 6 and daylight — reduce day/night flashing, bump shader settings, test Gastown performance
4. Splash preload screen — loading spinner while city tile data streams
5. Apple Store launcher with chasers — press Tab or mouse to jack car, cops start pursuit
6. Drive PASS and video — playtest car handling, record vertical slice demo
7. BP_Heat stars and system — three stars, wanted level meter, heat from crimes
8. Guns and firing — hold Shift, aim mouse, click to fire; shell casings and sound
9. NPCs and dynamic crowd — non-player characters, dialogue, mission feedback
10. Headless QA mode — run autoplay.dsl unattended, crash log reporting, fail fast
11. Package the .app — build macOS release binary, sign, notarize, ship

## Restart prompt

```
/loop 1h Vancouver Vice, today's goal: Unreal memory leans at 8-10 GB, male body fitted, mission two on the car jack, nearest task in the queue next. One Haiku subagent per step, mechanical work only; Sonnet for architecture decisions. Start with male body refit (polo shoulder seams), then walls+collision, then map detail/daylight. Next roadmap milestone: vertical slice packaged and QA'd on real Mac. If blocked or decision point: stop the loop, post findings, wait for guidance.
```
