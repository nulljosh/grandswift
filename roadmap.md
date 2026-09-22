# Rainjack roadmap

A first person Vancouver GTA, measured against GTA 3/4, not trying to be fully fledged.

## Shipped
- v0.1.0 top-down city, cars, cops, wanted stars
- v0.2.0 Vancouver map, street names, minimap
- v0.3.0 first person SceneKit, traffic, lane lines, Dock icon, app bundle
- v0.4.0 guns, car types, sidewalk walkers, synth sound, Victoria, Joshua/Alexandre swap, headless QA (`GS_QA=1 ./grandswift`, 15 checks)

- v1.0.0 tutorial, delivery missions, mouse look, day/night cycle, README, 22 QA checks

- v1.1.0 third person camera, pause menu, full screen, sharper textures, single instance, landing page (not deployed yet), CI

- v1.2.0 web build (site/play.html, three.js) is the lead: runs on Mac, Windows, Linux, iOS and Android browsers, installable as a PWA, touch controls. GTA style heat and stars (punch 1, kill 2, cops push to 5), cops shoot back, health, WASTED, aim assist, fists, missions (deliver, taxi, evade), XP and levels, 10 achievements, run and jump, 9 real landmarks, English Bay and Kits beaches, Lions Gate. Car stays visible when driving.

- v1.3.x all platforms (iOS, Mac, Windows, Linux, Android shells), Real Vancouver beta on Google 3D Tiles, AO + SMAA sharpness pass, mouse camera, punching with fight back or flee, bodies fall over

- v1.4.0 smooth people (shaped torso, hands, shoes, varied skin and hair), 100 walkers and 44 cars in lanes, neighbourhoods with their own crowds and lines, strangers who bump, chat or fight, speech bubbles, traffic, bird, gull and rain sound, rain that comes and goes

- v1.5.0 shotgun and SMG, car damage and explosions, radio stations, saves, five-mission story, live Vancouver weather (Open-Meteo), welcome card and clearer tutorial, Esc menu with Save and Exit, error handling, 31-check web test suite in CI, live demo on the landing page, Mac app icon and full screen

- v1.6.0 three heroes: Joshua (Gastown, yellow rain jacket, +50% cash, cools heat fast), Ben (Kitsilano, fastest, two-punch KOs), Alexandre (Victoria, steady aim, faster cars, armour); deterministic native test; QA playthrough fixes

- v1.7.0 real models: animated rigged people (walk, run, idle) and real car models (Ferrari 458, CC-BY), shapes as fallback

- v1.8.0 real ocean (reflective animated water), physical sky with a moving sun, Kits Beach with textured and wet sand, foam, driftwood logs, lifeguard towers, volleyball nets, towels and umbrellas; CI web test no longer flaky

- v1.9.0 renamed to Rainjack: repo nulljosh/rainjack, rainjack.heyitsmejosh.com (old domain redirects), apps and docs; Android activity was never committed (gitignore matched it), fixed

- v1.10.0 Real streets (site/city.html): downtown Vancouver built from OpenStreetMap, 3,359 real buildings at real heights, 8,378 streets with names, parks; walk and drive with collision against the real footprints (tools/osm.py)

- v1.11.0 street signs at 641 real intersections, 212 working traffic lights, 1,571 streetlights; walk into any building: 2,609 real named places from OSM, each with an interior built for its kind (cafe, bar, shop, grocery, bank, hotel, museum, cinema, library, lobby) and its real name on the wall

- v1.12.0 store crime: walk into a real 7-Eleven or shop, rob the till (G, two stars) or stop a robbery in progress (F, $200 reward); drunks start fights; cash, health and stars on the real-streets map

- v1.13.0 real-streets detail: 1024px facades with frames and floor lines, storefront glass on every ground floor, rooftop AC and water tanks, raised sidewalks, street trees, glass reflections, AO + SMAA

- v1.14.0 online: one shared Vancouver on a Cloudflare Durable Object, players see each other live on the real streets with name tags; landing and README updated

- v1.15.0 traffic on the real streets: 140 cars drive real road centre lines, keep right, turn at road ends, can hit you

## Next
- [ ] Move missions, cops, crowds and stars onto the real-streets map
- [ ] Coastline and water from OSM, Kits and Victoria
- [x] Online: one shared server (v1.14.0)
- [ ] Online chat, shared cops and stars
- [x] Civilians and heroes use the Xbot figure in neighbourhood and hero colours (v1.7.1)
- [ ] Detailed CC0 civilian characters with faces and clothes (gap vs GTA 3/4)
- [x] Mouse look
- [ ] Hood/dashboard view in cars, car damage and smoke
- [ ] Missions (a pickup, a chase, a hit), cash pickups, respawn at hospital
- [ ] Weapon switching (fists, pistol, shotgun), cops shooting back
- [ ] Day/night cycle and rain (it is Vancouver)
- [ ] Radio stations
- [ ] Real ferry to Victoria instead of a causeway
- [ ] Inactive hero visible in the world

## Cross platform
SwiftUI + SceneKit + AppKit are Apple only, so Windows and Linux need a port, not a flag.
- [ ] Pull the sim (Game, map, QA) into a pure Swift module with no Apple imports
- [ ] Windows/Linux front end: Swift + raylib (C, links everywhere), or a Godot port. raylib keeps the Swift sim.
- [ ] CI builds for macOS, Windows, Linux and attaches all three to each GitHub release

## Joshua Tree port
Joshua Tree is our from-scratch i386 kernel. No GPU, no Swift runtime there.
- [ ] Rewrite the sim in C (it is ~150 lines of logic)
- [ ] Software raycaster renderer (Wolfenstein style) on the JT framebuffer, keyboard via its PS/2 driver
- [ ] Ship as a JT app next to Stocks/Epiphany

## Resources
- Google Maps Platform Photorealistic 3D Tiles via Cesium: real Vancouver geometry. Needs a Maps API key and a 3D Tiles loader.
- Unreal MCP in Unreal Editor (UE 5.8 docs): Claude drives the editor directly. Real GTA 4 look = Unreal + Cesium + Google tiles, as a separate project.

## Native store apps
- [ ] iOS/Android store builds: wrap site/play.html (WKWebView on iOS, a WebView shell or Capacitor on Android). Until then the PWA installs from the browser on both.
- [ ] Native Mac build still lacks stars, missions, XP and landmarks from the web build. Port or make the Mac app a WebView of play.html.
