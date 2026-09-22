# Vancouver Vice

A GTA-style game in the real Vancouver. Live at vancouvervice.heyitsmejosh.com, repo nulljosh/vancouvervice.

## Run
`cd site && python3 -m http.server 8765`, then open /play.html (main game) or /city.html (real streets, `?area=victoria|kits|langley`).

## Test
`node tests/web.mjs`, `node tests/city.mjs`, `node tests/online.mjs`, `node tests/native.mjs`, `python3 tests/osm.py`. Web tests need Playwright with swiftshader, which is slow; allow minutes.

## Deploy
`npx wrangler deploy` (Worker `vancouvervice`: static site plus the online Durable Object in `worker.js`). A push deploys nothing. Tag `v*` to build every native app in GitHub Actions.

## Rules
- Never put text in the icon.
- Funny Vancouver satire is fine; don't make vulnerable groups the punchline.
- Native shells only, no Electron.
- The Cesium token lives in `.env` and `site/config.js`, both gitignored. The web token is locked to the game's domains.
- Update CHANGELOG, roadmap and the landing page with every user-facing release.

## The loop
See `docs/LOOP-HANDOFF.md` for where the loop stands and the restart prompt.
