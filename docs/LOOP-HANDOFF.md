# Vancouver Vice loop handoff (2026-09-22, morning)

## What the loop is

The loop runs autonomous single-item sprints on Vancouver Vice Unreal. One small feature per round: build it, verify it with a screenshot, commit, push, report back in under 8 words. If weekly usage hits 98%, the loop stops and updates this file before exiting.

## Where things stand

Epic launcher patching Unreal to 5.8.3 with Core Data (initial install stuck, now proceeding). Face scan complete: iPhone video imported, 3D head solved, MetaHuman has Joshua's face. Mission chain live: laptop heist at Apple Store, Art Gallery, 7-Eleven, Waterfront. face_scan.py and skill built for friends. Unreal 5.8.2 on LaCie, MCP 18000 streams real Vancouver via Google 3D Tiles. Player third-person at real Apple Store Georgia. Python controls editor. Tiles coarsen then sharpen. License Apache 2.0. Heroes Joshua, Ben, Alexandre. CI green.


**Resume here (2026-09-22, 11:25):** the Epic launcher wedged on the Core Data install (showed Initializing -100%). Plan: restart the Mac, Launcher > Unreal Engine > Library > the arrow on 5.8.2 > Options > tick MetaHuman Creator Core Data > Apply, keep Unreal closed until it says Installed. Then open Unreal with unreal/open.sh, run unreal/apply_missions.py through the bridge, and finish Joshua's MetaHuman: skin (light, freckles), curly ginger hair, glasses, cloud rig, textures, build, swap onto the player. Face is already conformed from the scan (/Game/Joshua, MHI in /Game/VancouverVice/Joshua).

## Next, in order

1. MetaHuman Core Data: launcher (even reinstalled via brew, 2026-09-22) freezes at 0% CPU the instant any install on the 5.8.2 LaCie engine is queued (log dies at QueueAppInstall manifest check). If it freezes, kill it and move Data/DownloadManager/*.json out or it refreezes on every open. Also tried: brew reinstall of the launcher, clearing .egstore/Pending on the LaCie. Still froze (5 tries). Untested: Removable Volumes in Privacy, or remove + reinstall 5.8 fresh. Meanwhile ship Joshua with the default skin.
2. Skin Joshua: light freckles, curly ginger hair and glasses (customize the MetaHuman asset)
3. Cloud rig: set up skeletal mesh and animation blueprint for the scanned face
4. Build and deploy: finalize MetaHuman, swap onto the player character for third-person gameplay
5. README shots: recapture the English Bay banner with the objective arrow and marker hidden, and replace the two browser shots (real-streets, kits-beach) with Unreal ones
5. Sprint with stamina: add stamina bar, hold Shift to sprint (foundation for gunplay and driving)
6. Guns and cars: integrate weapons and vehicle physics (first-person camera, steering, collisions)
7. Bake OSM geometry: pre-bake OpenStreetMap Vancouver for instant loading instead of streaming tiles

## Restart prompt

```
/loop Vancouver Vice Unreal build (~/Documents/Code/vancouvervice, UNREAL.md has the MCP recipe via unreal/mcp.py). FIRST check usage via the hook line / ~/.claude/scripts/usage.sh: if weekly_all >= 98%, commit, update docs/LOOP-HANDOFF.md, and stop the loop. Otherwise do ONE small item per round, in order: drivable car; three heroes (Joshua, Ben, Alexandre); a 7-Eleven to rob; cops and wanted stars; then more real Vancouver landmarks and missions. Verify each with a CaptureViewport screenshot, commit+push, then tell Joshua in under 8 words. No subagents.
```
