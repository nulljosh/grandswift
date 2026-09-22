# Contributing

Thanks for wanting to help. Here's how to get going.

## Run it
The game is plain web files in `site/`. Serve that folder and open it:

    cd site && python3 -m http.server 8765

Then open http://localhost:8765/play.html (main game) or /city.html (real streets).

## Test it
    npm install --no-save playwright && npx playwright install chromium
    node tests/web.mjs      # main game, 31 checks
    node tests/city.mjs     # real streets
    python3 tests/osm.py    # map data
    node tests/native.mjs   # app shells
    node tests/online.mjs   # online play against the live server

CI runs all of these plus a build for every platform on every push.

## Make a change
1. Branch from `main`.
2. Keep changes small and focused. One idea per pull request.
3. Run the tests. Add one if you add a feature.
4. Open a pull request using the template.

## Map data
`python3 tools/osm.py --area downtown|kits|victoria|langley` rebuilds a map from OpenStreetMap into `site/data/`.

## Style
Plain JavaScript, no build step. Comments explain why, not what. No em dashes in docs.
