# Grand Swift roadmap

A first person Vancouver GTA, measured against GTA 3/4, not trying to be fully fledged.

## Shipped
- v0.1.0 top-down city, cars, cops, wanted stars
- v0.2.0 Vancouver map, street names, minimap
- v0.3.0 first person SceneKit, traffic, lane lines, Dock icon, app bundle
- v0.4.0 guns, car types, sidewalk walkers, synth sound, Victoria, Joshua/Alexandre swap, headless QA (`GS_QA=1 ./grandswift`, 15 checks)

- v1.0.0 tutorial, delivery missions, mouse look, day/night cycle, README, 22 QA checks

## Next (gap vs GTA 3/4)
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
