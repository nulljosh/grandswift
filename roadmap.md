# Grand Swift roadmap

Goal: a first person Vancouver GTA, compared against GTA 3/4, not fully fledged.

## Resources to use
- Google Maps Platform Photorealistic 3D Tiles via Cesium: real Vancouver geometry. Needs a Maps API key and a 3D Tiles loader (Cesium for Unreal, or a SceneKit glTF tile streamer).
- Unreal MCP in Unreal Editor (UE 5.8 docs): lets Claude drive the editor directly. The path to a real GTA 4 look is Unreal + Cesium + Google tiles, as a separate project from this SwiftUI one.

## Gap vs GTA 3/4
- [x] First person 3D city, driving, traffic, peds, cops, wanted stars, minimap, street names
- [ ] Mouse look
- [ ] Sound (engine, sirens, radio)
- [ ] Weapons / missions
- [ ] Car damage, crash physics
- [ ] Day/night, rain (it is Vancouver)
