# Vancouver Vice roadmap

The goal: a GTA-style game set in the real Vancouver, good enough that friends play it for real. Measured honestly against GTA 3 through GTA 6.

## Where we are (end of 2026-09-22)

Unreal engine live: real Vancouver streets stream via Google 3D Tiles and MCP. Live at vancouvervice.heyitsmejosh.com, repo nulljosh/vancouvervice (local folder is still `~/Documents/Code/vancouvervice`).

- **Main game** (`site/play.html`): simplified Vancouver and Victoria. Fists, pistol, shotgun, SMG. Cars that smoke, burn and explode. Five-star cops that shoot back. Five story missions then endless side jobs. Three heroes with perks (Joshua in Gastown, Ben in Kits, Alexandre in Victoria), switched with a GTA V style camera flight. XP, levels, ten achievements, saves, live Vancouver weather, radio stations, neighbourhood crowds, strangers who bump, chat or fight.
- **Real streets** (`site/city.html`): downtown built from OpenStreetMap. 3,359 real buildings, 8,378 named streets, signs, traffic lights, streetlights, 140 cars in traffic, cop chases, walk-in interiors for 2,609 real places, 7-Eleven robberies, online play for everyone on the page. Victoria (`?area=victoria`, Tab flies there), Kits and Langley data exist. SkyTrain guideway, stations and one moving train are scaffolded.
- **Real Vancouver beta** (`site/real.html`): Google photorealistic 3D tiles through Cesium.
- **People:** 12 realistic Microsoft Rocketbox people (MIT) plus a Mixamo hero, converted with Blender.
- **Apps:** native shells on every platform. Windows in C# (WPF plus WebView2), Linux in C (GTK plus WebKitGTK), Mac and iOS in SwiftUI, Android in Java. No Electron.
- **Quality:** CI builds every platform and runs a 31-check web suite, a city gameplay test, map data tests and a Mac self-test.

Honest grade today: GTA 1/2 A-, GTA 3 C, GTA 4 D, GTA 5 and 6 F.

## Next up, in order

1. ~~**Unreal version.** UE 5.8.2 installed, MCP server running on 18000, real Vancouver from Google 3D Tiles streams live, player placed at Granville & Georgia, three heroes (Joshua, Ben, Alexandre) ready to play.~~
2. **Drivable car** (so players can get around, test vehicle physics, cops follow you). Commit and test it headless.
3. **Funny Vancouver chaos** (Joshua asked for all of these, GTA-style satire, nobody vulnerable as the punchline): bike lane rage cyclist, seagulls steal your hot dog at English Bay, SkyTrain surfing, crypto bro in a Patagonia vest, condo presale campout brawl, rain rage road fights, Lululemon sale stampede in Kits, Tesla bros drag racing in Coal Harbour, film crew blocking the street (steal the prop cop car), weed delivery mission, open house real estate agent chasing you, 2011-style hockey riot, wet coast driver doing 30 in the fast lane.
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

## Milestone: vertical slice (the first five minutes), then package it

Converge here first, then fan out. Joshua as himself (real skin, fitted glasses, black polo) bursts out of the Apple Store on Georgia, employees chase him out, he jacks the car at the curb, the cops come, he loses them, he pawns the Mac minis on Granville. Package it as a Mac .app, QA the real app, ship it as 1.27.

- [ ] unreal/package.sh: RunUAT BuildCookRun, Development, Mac, editor closed so it gets the RAM; restricted Cesium token in the build.
- [ ] In-game autoplayer behind a launch flag (-autoplay) so the packaged app tests itself, writes a PASS/FAIL file and a screenshot.
- [ ] Build in the editor without Play; QA on the packaged app at each milestone.

After the slice: fan out across graphics (street-level tile detail, lighting), story (missions 5 to 14), systems (guns, minimap, radio), people (Ben, Alexandre, family scans), audio, more cities.

## Unreal build: gaps against GTA 5, in build order

- [ ] Driving QA passes: E in, W drives, E out (python3 unreal/qa.py drive).
- [ ] Core Data look: fair freckled skin, curly ginger hair, male body, black crewneck over a white collar.
- [ ] Wardrobe on the male body: black polo (rebuild, straight hem, clean shoulder) and a grey hoodie with a parody "Gastown Polo" bear logo top left (bear in a blue-and-green toque holding a coffee, no real brand marks).
- [ ] Smooth walk: hidden mannequin drives, Joshua's body follows (leader pose, wired, needs a PIE check).
- [ ] Fast travel on Tab between Vancouver, Victoria, Seattle, Toronto, New York (unreal/fasttravel.dsl).
- [ ] Cops and stars (docs/COPS.md): BP_Heat, pursuit cars, search circle.
- [ ] Minimap top right: top-down scene capture of the Google tiles, stars beside it.
- [ ] Apple Store opener: two employees chase you out, Mac minis line in the corner.
- [ ] Pawn shop on Granville, cash counter.
- [ ] Guns: rifle from the first-person template on a third-person aim.
- [ ] Ben and Alexandre as switchable MetaHumans (face scans).
- [ ] Brian (Dad), Christine (Mom) and Sarah (sister) as MetaHumans from iPhone face scans (/face-scan), for the garage, dinner and dock scenes.
- [ ] Missions 5 to 14 from docs/STORY.md.
- [ ] Mac .app release, splash and loading screen while the city streams in.
- [ ] Windows .exe: package on a Windows PC or a rented cloud Windows GPU box (Unreal only packages Windows on Windows).

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

Open Claude Code in `~/Documents/Code/vancouvervice` and paste:

```
/loop Work through roadmap.md for Vancouver Vice, top to bottom. One item per round: build it, test it headless (node tests/web.mjs, node tests/city.mjs), deploy with npx wrangler deploy, commit, tag a release, update the landing page and README if it's user-facing, and check it off here. Keep usage lean: one Haiku subagent at most. Self-grade honestly against GTA 3 after each round.
```

- [ ] Apple Store heist opener: Apple employees chase the player out the door (AI pawns that run at the player during mission one, no navmesh needed, AddMovementInput toward player), Mac mini props to grab
- [ ] Glasses on Joshua (attach a glasses mesh to the head socket)
- [ ] In-game graphics setting: a Low/Medium/High key that sets the tileset MaximumScreenSpaceError (12/6/3) at runtime, so nearby streets are sharp and far tiles stay cheap on 16 GB
