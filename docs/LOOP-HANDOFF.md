# Vancouver Vice loop handoff (updated 2026-09-22, morning)

## What the loop is
A self-paced loop that works through `roadmap.md` one item per round: build it, test it headless, deploy, commit, tag, update the landing page and changelog, self-grade against GTA 3.

## Where things stand
Version 1.26 is live at vancouvervice.heyitsmejosh.com. Web tests, city tests and online tests (10 of 10) pass. Native apps build for every platform in CI. Unreal 5.8.2 is installed at `/Volumes/LaCie/UE_5.8` and the project lives at `/Volumes/LaCie/Unreal/VancouverVice` with Cesium for Unreal in its Plugins folder. `unreal/open.sh` opens it with the MCP server on port 18000. Resume prompt: `docs/RESUME-PROMPT.txt`. The Cesium web token still needs `https://vancouvervice.heyitsmejosh.com` added (Joshua, in the Cesium dashboard). Weekly Claude usage was at 92 percent when the loop stopped; it resets Saturday night.

## Next, in order
1. Unreal: run `unreal/setup_vancouver.py` through the MCP, then heroes, a car, a 7-Eleven, cops and stars.
2. Funny chaos list from the roadmap, one or two per round (bike lane rage is first).
3. Move missions and heroes onto the real streets.
4. Ride the SkyTrain.

## Restart prompt
```
/loop Work through roadmap.md for Vancouver Vice, top to bottom. One item per round: build it, test it headless (node tests/web.mjs, node tests/city.mjs, node tests/online.mjs), deploy with npx wrangler deploy, commit, tag a release, update the landing page, README and CHANGELOG if it's user-facing, and check it off in roadmap.md. Keep usage lean: one Haiku subagent at most. Self-grade honestly against GTA 3 after each round.
```
