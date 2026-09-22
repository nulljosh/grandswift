# Vancouver Vice loop handoff (2026-09-22, morning)

## What the loop is

The loop runs autonomous single-item sprints on Vancouver Vice Unreal. One small feature per round: build it, verify it with a screenshot, commit, push, report back in under 8 words. If weekly usage hits 98%, the loop stops and updates this file before exiting.

## Where things stand

Unreal 5.8.2 on the LaCie drive. MCP server on 18000 streams real Vancouver via Google 3D Tiles and raw HTTP client. Player in third-person at the real Apple Store on Georgia. Joshua scanned his face via Live Link Face iPhone app, becoming a MetaHuman character. Three missions wired at real places: Art Gallery, rob the 7-Eleven on Granville, Waterfront Station (beacons and objectives). Python bridge controls Unreal editor. Tiles load coarse first then sharpen for instant play. License Apache 2.0. Heroes: Joshua downtown, Ben Kitsilano, Alexandre Victoria. Landing boots the level.

## Next, in order

1. Drivable car: rig vehicle, test steering/braking, spawn near player, cops chase on collision
2. sprint with stamina (hold Shift), guns from the First Person pack: add FP camera toggle option, test weapon aim and movement
3. Vehicle stealing pack: let player steal cars, vehicle variety, damage states visible
4. Finish MetaHuman: complete Joshua's face scan into a full body model with animations
5. Bake OSM geometry: pre-bake OpenStreetMap Vancouver for instant loading instead of streaming tiles

## Restart prompt

```
/loop Vancouver Vice Unreal build (~/Documents/Code/vancouvervice, UNREAL.md has the MCP recipe via unreal/mcp.py). FIRST check usage via the hook line / ~/.claude/scripts/usage.sh: if weekly_all >= 98%, commit, update docs/LOOP-HANDOFF.md, and stop the loop. Otherwise do ONE small item per round, in order: drivable car; three heroes (Joshua, Ben, Alexandre); a 7-Eleven to rob; cops and wanted stars; then more real Vancouver landmarks and missions. Verify each with a CaptureViewport screenshot, commit+push, then tell Joshua in under 8 words. No subagents.
```
