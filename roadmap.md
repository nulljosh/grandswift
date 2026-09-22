# Vancouver Vice roadmap

The goal: a GTA-style game set in the real Vancouver, good enough that friends play it for real. Measured honestly against GTA 3 through GTA 6.

## Where we are (end of 2026-09-21)

Built in one day. Live at vancouvervice.heyitsmejosh.com, repo nulljosh/vancouvervice (local folder is still `~/Documents/Code/rainjack`).

- **Main game** (`site/play.html`): simplified Vancouver and Victoria. Fists, pistol, shotgun, SMG. Cars that smoke, burn and explode. Five-star cops that shoot back. Five story missions then endless side jobs. Three heroes with perks (Joshua in Gastown, Ben in Kits, Alexandre in Victoria), switched with a GTA V style camera flight. XP, levels, ten achievements, saves, live Vancouver weather, radio stations, neighbourhood crowds, strangers who bump, chat or fight.
- **Real streets** (`site/city.html`): downtown built from OpenStreetMap. 3,359 real buildings, 8,378 named streets, signs, traffic lights, streetlights, 140 cars in traffic, cop chases, walk-in interiors for 2,609 real places, 7-Eleven robberies, online play for everyone on the page. Victoria (`?area=victoria`, Tab flies there), Kits and Langley data exist. SkyTrain guideway, stations and one moving train are scaffolded.
- **Real Vancouver beta** (`site/real.html`): Google photorealistic 3D tiles through Cesium.
- **People:** 12 realistic Microsoft Rocketbox people (MIT) plus a Mixamo hero, converted with Blender.
- **Apps:** native shells on every platform. Windows in C# (WPF plus WebView2), Linux in C (GTK plus WebKitGTK), Mac and iOS in SwiftUI, Android in Java. No Electron.
- **Quality:** CI builds every platform and runs a 31-check web suite, a city gameplay test, map data tests and a Mac self-test.

Honest grade today: GTA 1/2 A-, GTA 3 C, GTA 4 D, GTA 5 and 6 F.

## Next up, in order

1. **Unreal version.** UE 5.8.2 is installing to `/Volumes/LaCie/UE_5.8` (Epic's launcher is slow and crashed once; press Resume). When `UnrealEditor.app` exists: create a Third Person project, enable the Unreal MCP, Python and Cesium for Unreal plugins, add the Unreal MCP to Claude, run `unreal/setup_vancouver.py` with `CESIUM_ION_TOKEN` from `.env`. See `UNREAL.md`.
2. **Funny Vancouver chaos** (Joshua asked for all of these, GTA-style satire, nobody vulnerable as the punchline): bike lane rage cyclist, seagulls steal your hot dog at English Bay, SkyTrain surfing, crypto bro in a Patagonia vest, condo presale campout brawl, rain rage road fights, Stanley Park geese, Lululemon sale stampede in Kits, Tesla bros drag racing in Coal Harbour, film crew blocking the street (steal the prop cop car), weed delivery mission, open house real estate agent chasing you, 2011-style hockey riot, wet coast driver doing 30 in the fast lane.
3. **Move gameplay onto the real streets.** Missions, heroes, weapons, radio and weather from the main game, running on the OpenStreetMap city. Eventually the real streets become the main game.
4. **SkyTrain for real.** Ride it (enter at a station, fast travel between stations), trains on every line, underground sections downtown instead of the elevated scaffold, SkyTrain surfing.
5. **Bigger map.** Join downtown, Kits, Burnaby, Richmond, North Shore, Surrey and Langley into one city with streaming. Bridges and the Sea to Sky.
6. **Real Victoria gameplay.** The ferry from Tsawwassen, Alexandre's missions, the Legislature, the Inner Harbour.

## Gaps against GTA 3

- A story with characters, cutscenes and a reason to care. We have five text missions.
- Voice acting or at least voiced one-liners.
- Real radio stations with DJs and ads (ours are procedural beats).
- More weapons (bat, knife-free melee, rifle, grenades), weapon pickups and ammo shops.
- Hospitals and police stations you respawn at, safehouses you save at.
- Vehicle variety: bikes, boats (the harbour), a helicopter.
- Car damage that shows (dents, lost doors), not just smoke and fire.

## Gaps against GTA 4

- Physics: ragdolls, heavy driving, crashes that feel real.
- Animation: people who stumble, fall, get up, react, not just walk and idle.
- A phone: calls, texts, contacts, mission givers.
- Pedestrians with daily routines, jobs, homes, conversations.
- Interiors that feel lived in (ours are generated rooms).
- Lighting at night: headlights, neon, wet reflections.

## Gaps against GTA 5

- Three full characters with their own stories, not just perks.
- Heists: plan, pick a crew, pull the job.
- A big map with countryside, mountains, water, air.
- Property, businesses, stocks.
- Online modes: races, deathmatch, shared cops and heists.

## Gaps against GTA 6 (previews)

- Photoreal everything: this is the Unreal plus Google tiles path.
- Crowds of hundreds with unique faces (MetaHumans).
- Social media satire inside the game (an in-game Instagram and TikTok).
- Weather and time that change how the city behaves.

## Quick polish list (small, any session)

- Better car models (more than the Ferrari): search MIT or CC0 glTF cars.
- More people models: the rest of the Rocketbox set, plus Mixamo characters.
- Add the vancouvervice domain to the Cesium token so the 3D beta works there.
- Signing keys for Windows, Mac notarisation and Android so apps install without warnings (`apps/README.md`).
- App Store: screenshots, description, privacy answers, $0.99 upfront per GTM.md.
- Refresh README screenshots (the 7-Eleven shot still shows the old soldier model).
- Move the old technical README notes into `docs/ARCHITECTURE.md`.

## How to pick this up

Open Claude Code in `~/Documents/Code/rainjack` and paste:

```
/loop Work through roadmap.md for Vancouver Vice, top to bottom. One item per round: build it, test it headless (node tests/web.mjs, node tests/city.mjs), deploy with npx wrangler deploy, commit, tag a release, update the landing page and README if it's user-facing, and check it off here. Keep usage lean: one Haiku subagent at most. Self-grade honestly against GTA 3 after each round.
```
