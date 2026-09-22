# Grand Swift

A crime game set in Vancouver and Victoria. It runs in any browser, phones included, and there's a native Mac app too.

You start downtown at Granville and Georgia. A short tutorial covers walking, shooting, stealing a car, driving to a beacon and switching characters. After that the missions start: car deliveries, taxi fares, and chases where you get three stars and then lose the cops. Punch someone and you get a star. Kill cops and you climb to five, with more cars coming for you and shooting back.

## Play
- Web: open `site/play.html` on a local server (`python3 -m http.server -d site`), or add it to your home screen on iOS or Android.
- Mac: `./build.sh && open "Grand Swift.app"`

## Controls
W A S D move, Shift run, Space jump, mouse look (click to lock), click or Enter to attack, F punch, Q fists or pistol, E get in or out of a car, Tab switch between Joshua and Alexandre, Esc pause, F full screen. On phones: a stick on the left, drag to look, and buttons on the right.

## What's in it
Fists that land: people fight back or run, and they fall over when they go down. A Real Vancouver beta (`site/real.html`) streams the actual city from Google's photorealistic 3D tiles through Cesium.

## Platforms
Web, plus apps for iOS and Mac (`apps/apple`), Windows and Linux (`apps/desktop`), and Android (`apps/android`). Tagging a release builds all of them in CI.

## Inside the game
Nine real landmarks: Canada Place, Harbour Centre, the Gastown steam clock, the Art Gallery, BC Place, Rogers Arena, Science World, Granville Island and the BC Legislature. English Bay and Kits beaches, Stanley Park, the Lions Gate, Burrard and Granville bridges. Traffic, people walking down the sidewalks, five star heat that cools once the cops lose sight of you, health, WASTED and BUSTED, XP and levels, and ten achievements saved in your browser.

## How it stacks up
Graded honestly against the real thing.

| Game | Grade | Why |
|---|---|---|
| GTA 1/2 (top down, 1997) | B+ | Same loop: steal, drive, stars, missions. It's also 3D and runs on phones. |
| GTA 3 (2001) | D+ | The shape is right: third person, stars, missions, a real city. What's missing: a story, voices, radio, car damage, physics, weapon variety, interiors, a map bigger than downtown. |
| GTA 4 (2008) | F | No physics engine, no ragdolls, blocky people, and a city made of boxes. |
| GTA 5 (2013) | F | That game had a thousand people working on it for five years. |
| GTA 6 (previews) | F | Photoreal streets and crowds. That calls for a real engine and real map data. |

The honest ceiling for this codebase is a solid GTA 2 to GTA 3. Getting anywhere near GTA 4 or later means changing engines, not polishing this one.

## The GTA 4+ path
Two resources make that possible, and neither is set up yet:
- **Google Maps Platform Photorealistic 3D Tiles**, streamed through Cesium, gives the real Vancouver: every building, street and tree. It needs a Google Maps API key with billing turned on.
- **Unreal MCP in Unreal Editor** (UE 5.8) lets Claude drive the editor directly. Cesium for Unreal loads those tiles, and Unreal brings physics, lighting and animation.

That's a separate project. Unreal needs a large download and disk space, and Epic has to be signed into by hand.

## QA
`GS_QA=1 ./grandswift` plays the Mac game with no window and checks 23 things. The web build is tested headless with Playwright. CI runs the Mac checks on every push.

See roadmap.md for what's next.
