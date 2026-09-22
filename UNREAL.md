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
