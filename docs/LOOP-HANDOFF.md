# Vancouver Vice loop handoff (2026-09-22, morning)

## What the loop is

The loop runs autonomous single-item sprints on Vancouver Vice Unreal. One small feature per round: build it, verify it with a screenshot, commit, push, report back in under 8 words. If weekly usage hits 98%, the loop stops and updates this file before exiting.

## Where things stand

Unreal 5.8.2 runs on the LaCie drive. MCP server on 18000 streams real Vancouver from Google 3D Tiles. Player starts at Granville and Georgia. Three heroes wired: Joshua downtown, Ben in Kitsilano, Alexandre in Victoria. No cars yet, no robberies, no cops, no missions. Landing page boots the Unreal level. Commits adb54af and 4e7fa76 pushed and live.

## Next, in order

1. Drivable car: rig a vehicle model, test steering and braking, spawn near player, cops chase you when you hit things
2. Three heroes: swap bodies on Tab, each gets unique appearance and mission set (Joshua street crime, Ben relaxation, Alexandre delivery)
3. Seven-Eleven robbery: enter a store, point gun, get cash, get wanted star, cops arrive
4. Cops and wanted stars: five-star system matching GTA, AI chases escalate with stars, wanted level shows in HUD
5. More landmarks: add real Vancouver places (English Bay, Pacific Central, Rogers Arena, Science Centre, UBC), make them navigable and mission-relevant

## Restart prompt

```
/loop Vancouver Vice Unreal build (~/Documents/Code/vancouvervice, UNREAL.md has the MCP recipe via unreal/mcp.py). FIRST check usage via the hook line / ~/.claude/scripts/usage.sh: if weekly_all >= 98%, commit, update docs/LOOP-HANDOFF.md, and stop the loop. Otherwise do ONE small item per round, in order: drivable car; three heroes (Joshua, Ben, Alexandre); a 7-Eleven to rob; cops and wanted stars; then more real Vancouver landmarks and missions. Verify each with a CaptureViewport screenshot, commit+push, then tell Joshua in under 8 words. No subagents.
```
