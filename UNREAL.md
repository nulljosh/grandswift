# Unreal plan (Vancouver Vice 2)

The GTA 4+ version. Real Vancouver, real engine, Claude building it through Unreal's own MCP.

## Stack
- Unreal Engine 5.8, which ships an experimental Unreal MCP plugin. Turn on Unreal MCP, Terminal and Editor Tool Set, restart, then point Claude Code at the local MCP server.
- Cesium for Unreal streams Google Photorealistic 3D Tiles. A free Cesium ion account is enough, so no Google billing key is needed.
- The City Sample project gives cars, crowds and traffic to start from. unreal-agent-harness shows agents building cities this way, including a real NYC through Cesium.

## Steps
1. Free up disk: UE 5.8 plus City Sample is 100 GB or more, and the Mac has 54 GB free. Install to the LaCie drive.
2. Joshua: install the Epic Games Launcher, sign in, install UE 5.8. Make a free Cesium ion account and give Claude the token.
3. Claude: new project from the Third Person template (plus City Sample for cars and crowds), run `unreal/setup_vancouver.py` to drop in the georeference, the Google tiles, a real sun and a player start, then, enable the plugins, add Cesium, drop the Vancouver tiles at Granville and Georgia, then port the rules (stars, missions, two heroes) into Blueprints.

## Links
- https://dev.epicgames.com/documentation/unreal-engine/unreal-mcp-in-unreal-editor
- https://cesium.com/learn/unreal/unreal-photorealistic-3d-tiles/
- https://github.com/per-simmons/unreal-agent-harness

## Current setup (2026-09-22)
- Engine: `/Volumes/LaCie/UE_5.8` (5.8.2). Project: `/Volumes/LaCie/Unreal/VancouverVice`.
- Open it with `unreal/open.sh`. That starts the MCP server on port 18000 (port 8000 belongs to the local LLM server).
- Claude is registered with `claude mcp add --transport http unreal http://127.0.0.1:18000/mcp -s user`. New sessions see it; run `/mcp` to check.
- First launch needed Xcode's Metal toolchain: `xcodebuild -downloadComponent MetalToolchain`.
- Cesium for Unreal comes from Fab in the Epic launcher (Install to Engine, 5.8).

## Vancouver is in (2026-09-22)
- Google 3D Tiles stream into `Lvl_ThirdPerson`: CesiumGeoreference at Granville & Georgia (49.2833, -123.1187, 80 m) plus a Cesium3DTileset on ion asset 2275207 with the token from `.env`. No Cesium ion panel login needed.
- The MCP can't `import unreal`. Drive it with `unreal/mcp.py` (raw HTTP client) through `call_tool`: SceneTools `add_to_scene_from_class`, ObjectTools `set_properties`. Property names are lowerCamel (`ionAssetId`, `originLatitude`) and `values` is a JSON string.
- First launch off the LaCie takes about 5 minutes (shader compile). No window until it finishes.

## Heroes (Joshua's call, 2026-09-22)
- Game opens as Joshua running around downtown Vancouver (player start at Granville & Georgia, street level, z -6350 (lower clips the street and spawns a floating camera instead of the mannequin); street is about z -6660 to -6700. A hidden Plane "Spawn Catch Pad" at z -6690 catches the player before tile collision streams in).
- Switch to Ben: chilling or driving around Kitsilano.
- Switch to Alexandre: delivery jobs, and working in an office in downtown Victoria on Vancouver Island.
- The template arena still floats about 69 m above Granville & Georgia. Delete it once the character can walk on the tiles.
- Tile detail: maximumScreenSpaceError 8 (sharp). Lumen and virtual shadows are off in Config/DefaultEngine.ini for frame rate.
