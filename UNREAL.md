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

## Next, Joshua's order (2026-09-22)
1. Character skin: a real Joshua (MetaHuman) on the mannequin skeleton.
2. Sharper city (tile detail is at 4, the max worth running; street level is capped by Google's photo scan).
3. Guns (First Person pack) and stealing cars (Vehicle pack).
4. First mission: rob a 7-Eleven downtown.
Boot to playable takes a minute or two while tiles stream. Expected.

## Apple Store spawn + QA bridge (2026-09-22)
- Spawn: "Start: Apple Pacific Centre" at (814, 300, -6350) on the Georgia St sidewalk, facing the store; catch pad follows at z -6700.
- Real places in Unreal coords (from the georeference): Apple (814, 1614), Art Gallery (-14005, 5010), Waterfront Station (51118, -26606), 7-Eleven 1294 Granville (-63876, 80134). Tile heights change with LOD, so trust the proven street z near spawn.
- `unreal/qa.py '<python>'` runs full Unreal Python in the editor through Content/Python/init_unreal.py (copy in unreal/Python). It can save the level: `unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)`.
- Tile cache: MaxCacheItems=100000 under CesiumRuntimeSettings in Config/DefaultEngine.ini (default 4096), so revisited streets load from disk. Baking the tiles into the project is off the table: Google 3D Tiles terms only allow caching.

## Face scan and packs (2026-09-22)
- Face scan: Live Link Face take unzipped to /Volumes/LaCie/Unreal/Captures. Import with `unreal.CaptureManagerIngestBlueprintLibrary.ingest_live_link_face(dir, CaptureManagerConversionParams(), on_success, on_failure)` (async, callbacks take 3 args). Never call the _sync or MetaHumanCaptureSourceSync versions from the bridge: they block the game thread and deadlock the editor.
- Gun and car Blueprints copied from Templates/TP_FirstPersonBP and TP_VehicleAdvBP into Content; ChaosVehiclesPlugin enabled in the .uproject. The car and gun meshes live in the Add Feature pack flow, not in those folders, so the pack dialog may still be needed once.
- Face scan pipeline for anyone: unreal/face_scan.py <zip> <Name> [frame], documented in the face-scan skill. Joshua conformed successfully (import_from_identity SUCCESS).
- commit_skin_settings asserts (BodyTexture, crash) until MetaHuman Creator Core Data is installed. Install it in the launcher before any skin, rig or texture step.
- Launcher gotcha: never edit ~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests/*.item. Flipping bIsIncompleteInstall made the launcher forget the whole 5.8.2 install (files stayed on disk; restoring the .item from a backup fixed it). The launcher will not install anything while Unreal or its helpers (UnrealTraceServer, UnrealEditorServices) are running.
- Smooth walk (next, after the editor restarts on the Core Data engine): BP_ThirdPersonCharacter has a hidden Body component (Joshua body). Swap Mesh back to SKM_Quinn_Simple (hidden, AlwaysTickPoseAndRefreshBones), show Body, and in UserConstructionScript add (Components|SkinnedMesh|SetLeaderPoseComponent :self (Variables|Default|GetBody) :NewLeaderBoneComponent (Variables|Character|GetMesh)). New components only get a Get node after an editor restart.
- Glasses: unreal/glasses.py (Blender, headless) makes unreal/assets/glasses.fbx; attached to the Mesh head socket by the construction script (Python cannot set a socket on a Blueprint component).

## Running it unattended (phone-friendly)
- `sh unreal/doctor.sh` prints health: editor, control port, RAM and swap, crash leftovers, recent errors.
- `sh unreal/doctor.sh heal` clears the crash report window and orphaned helpers, relaunches the editor if it died (refuses when RAM is too tight), and restarts the MCP server when a crashed editor left port 18000 stuck. Run it before any session from Claude mobile.
- Long operations (MetaHuman builds) outlast the bridge's 60 s default: `QA_TIMEOUT=900 python3 unreal/qa.py '...'`.
- Crash on 2026-09-22: the MetaHuman build succeeded, then asserted in MakeUniqueObjectName while unpacking. Most likely cause: Core Data cloned from the 5.8.3 install into the 5.8.2 engine. If it repeats, finish the 5.8.3 install at /Volumes/LaCie/Epic/UE_5.8 and point open.sh at it.
- Close the Epic launcher when Unreal is building: 16 GB of RAM cannot hold both plus MetaHuman texture synthesis.
