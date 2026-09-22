# Vancouver Vice loop handoff (2026-09-22, just after midnight)

## What the loop is
A self-paced loop that works through `roadmap.md` one item per round: build it, test it headless, deploy, commit, tag, update the landing page and changelog, self-grade against GTA 3.

## Where things stand
Version 1.26 is live at vancouvervice.heyitsmejosh.com. Web tests, city tests and online tests (10 of 10) pass. Native apps build for every platform in CI. Unreal 5.8.2 is still installing to `/Volumes/LaCie/UE_5.8`. The Cesium web token still needs `https://vancouvervice.heyitsmejosh.com` added (Joshua, in the Cesium dashboard). Weekly Claude usage was at 92 percent when the loop stopped; it resets Saturday night.

## Next, in order
1. Unreal: once `UnrealEditor.app` exists, make the project, turn on the Unreal MCP, Python and Cesium plugins, run `unreal/setup_vancouver.py`.
2. Funny chaos list from the roadmap, one or two per round (bike lane rage is first).
3. Move missions and heroes onto the real streets.
4. Ride the SkyTrain.

## Restart prompt
```
/loop Work through roadmap.md for Vancouver Vice, top to bottom. One item per round: build it, test it headless (node tests/web.mjs, node tests/city.mjs, node tests/online.mjs), deploy with npx wrangler deploy, commit, tag a release, update the landing page, README and CHANGELOG if it's user-facing, and check it off in roadmap.md. Keep usage lean: one Haiku subagent at most. Self-grade honestly against GTA 3 after each round.
```
