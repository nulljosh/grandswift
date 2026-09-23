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

## Blocky city in Play (2026-09-23)
- Symptom: at the Apple Store spawn the Google tiles stay as coarse grey/blue blocks in Play and never sharpen.
- What the evidence showed: not a Cesium error (no failed loads in the log, network fine). The editor was starved of memory. `footprint -p <editor pid>` read 20 GB (11 GB of it GPU, "IOAccelerator") on a 16 GB Mac, later 46 GB after a Play session was left running for hours. Frames took 3 to 27 s ("Ignoring very large delta" and audio underruns all through the log), and Cesium only refines tiles as frames tick, so load progress crawled (45% after 2.5 min). When other apps freed RAM the same Play hit 35 fps and progress climbed normally; a Play left running reached 100% (3977 tile components).
- Turned back: tileset maximum_cached_bytes 4 GB to 256 MB (the default; 4 GB per tileset, and the editor world and the Play world each keep one), maximum_simultaneous_tile_loads 64 to 20, enable_double_sided_collisions off. Saved in the level.
- GPU memory Unreal has grabbed is not handed back when Play stops. Only an editor restart clears it, so restart before a long test session if `footprint` shows the editor well past 10 GB.
- House rules for tests on this Mac: t.MaxFPS 30 and r.ScreenPercentage 60 while testing, Lumen off, never raise tile detail or cache sizes, and never leave Play running. Start, wait for tiles, check, stop.
- Joshua accepts a slow, polygonal city for now. Do not chase photoreal until the Mac has more headroom.
- Fitted glasses (2026-09-23): the Glasses component uses glasses_fit (M_Tortoise, M_Lens, M_Rivet). It sits at the inverse of the face head bone ref pose, relative to the Mesh "head" socket: location (-154.66, -0.85, 0), rotation yaw -90. The mesh is modeled in face-mesh space, so glasses_fit.json's offset (mesh axes, not bone axes) is not used. Measured in Play: lens centres 0.3 cm off the eyes sideways, 0.7 cm low, 2.9 cm in front of the eye centres. Reapply with unreal/glasses_install.py.
- The Body and Face components point at /Engine/Transient copies of SKM_Joshua_BodyMesh and SKM_Joshua_FaceMesh, not the saved assets under /Game/Unpacked/Joshua. They will come up empty after an editor restart. Repoint them at the saved assets (identical bones, checked).
- The Face component has no leader pose in Play (leader None), so the face holds its bind pose while the body animates.

## Packaging and self-test (2026-09-23)

- `sh unreal/package.sh` packages a Development Mac `.app` via RunUAT `BuildCookRun` (`-project -platform=Mac -clientconfig=Development -build -cook -stage -pak -archive -archivedirectory=/Volumes/LaCie/Unreal/Builds/<date>`). It refuses to run if `UnrealEditor` is still open (the cook wants the RAM the editor is holding) or if free RAM/swap are too tight, reusing `doctor.sh`'s thresholds idea but stricter (25% free / 80% swap, vs `doctor.sh`'s 15%/90%, because a cook runs far longer than an editor relaunch). It logs to `/Volumes/LaCie/Unreal/Builds/<date>/package.log` (symlinked at `unreal/package.log` for `tail -f`), and prints the `.app` path on success.
- First cook on this Mac has not been timed yet; budget at least 30-60 minutes for a first full cook of the Vancouver level (shader compile plus cooking the Cesium/vehicle/first-person template content), and expect it to compete with disk I/O to the LaCie drive. Close the Epic launcher too, same as any other heavy Unreal operation on this machine.
- Before any public release, swap the Cesium ion token baked into the build for a restricted one (locked to this app), the same way `CLAUDE.md` already locks the web build's token to the game's domains. `unreal/package.sh` prints a reminder every run; it does not enforce this.
- QA now happens on the packaged `.app`, not in the editor's Play mode: `unreal/qa.py` drives Play inside the editor, which is fine for iteration, but the milestone's real gate is the packaged build launched with `-autoplay` (see `unreal/autoplay.dsl`, still a draft, not yet applied to `BP_ThirdPersonCharacter` via `apply_missions.py`). Once applied, run the `.app` with `-autoplay`, then check `Saved/Autoplay/result.txt` for a `PASS`/`FAIL` line and a timestamp, and `Saved/Screenshots/` for the `HighResShot`.
- `unreal/autoplay.dsl` flags a few node names as uncertain in its own comments (command-line param check, writing the result file from a packaged build with no editor-only plugins, and the console-command node for `HighResShot`); confirm those in the node picker before applying.

## Lean settings (2026-09-23)
- Tileset MaximumScreenSpaceError 12 (BP_Missions BeginPlay and Tick, and the actor). Coarser city, but the tile textures fit the streaming pool instead of wanting three times it.
- maximum_simultaneous_tile_loads 20. Fewer tiles decoding at once, less memory spike, slower first load.
- DefaultEngine.ini [SystemSettings]: r.Streaming.PoolSize 1500 (up from 1000, a small bump, not a fix), r.Shadow.Virtual.Enable 0, r.Shadow.MaxResolution and r.Shadow.MaxCSMResolution 1024 (softer, blurrier shadows, much cheaper).
- Tests only, set per session: t.MaxFPS 30, r.ScreenPercentage 60. Lumen stays off. Editor viewport Realtime off outside Play. Auto reimport and content folder monitoring off, so Blender rewriting an FBX no longer pops an import dialog; import new FBX versions by hand.
- "PROFILING WITH AI LOGGING ON" shows only while stats collect. stat none (and stat stopfile) clears it. Do not use DisableAllScreenMessages: the mission line is a PrintString.
- Drive QA passed its real checks (mission two index 2, drove 8.8 m, back out) with frames taking up to 99 s. The editor had grown to a 54 GB footprint. Restart the editor before the next long session.

## Only load what's near the player (2026-09-23)
- Tileset: frustum and fog culling on, preload ancestors and siblings off, forbid holes off, enforce culled SSE on at 64 (tiles off screen drop to coarse), cache 256 MB, 20 loads at once, SSE 12. No distance cap yet: CesiumTileExcluder exists but needs a Blueprint subclass with ShouldExclude, not done.
- Measured on a freshly restarted editor, 5 minutes of Play at the Apple Store spawn: footprint 8.2 GB before, 9.2 GB at 60 s, 9.6 GB at 300 s, 9.0 GB after stopping. Swap 4.5 GB before, 4.1 to 6.7 GB during. Tiles hit 100% within 60 s at about 28 fps (capped at 30).
- Compare the old editor session: 20 GB, then 54 GB, with frames taking seconds. The restart plus these settings is the fix. Restart when doctor.sh says RESTART DUE.
- Midday sun (2026-09-23): directional light pitch -50, intensity 10 (was 3, which read as dusk blue), sky light recaptured. Tileset SSE 8: at 6 the Play footprint reached 16 to 17 GB, over the 15 GB line.
- Male body: build_meta_human after restart produced a mesh identical to the old female one (same bounds, same joints, compared in Blender). The saved male constraints did not reach the build. Re-committing the body state and rebuilding in the same session was denied by the permission classifier.

## Character fix pass, skin (2026-09-23)
- Root cause of the red-brown untextured skin: the Body material (`/Game/Unpacked/Joshua/Body/Materials/MI_Body_Baked_VT`) pointed at real, correctly-sized baked VT textures (not literal placeholder assets), but `/Game/Joshua`'s `body_textures` and `synthesized_face_textures` maps were both empty and `skin_settings` had never been committed, so the "baked" textures were flat average-tone bakes, not real detail. Not a lighting issue this time (lighting was already midday from the prior session).
- Fix: `MetaHumanCharacterEditorSubsystem.request_texture_sources(character, params)` with `params.blocking = True` (synchronous, ran inside `ScopedMetaHumanCharacterEditor`), then `commit_skin_settings(mh, mh.skin_settings)`, then saved `/Game/Joshua`. `body_textures` and `synthesized_face_textures` are now populated (11 body texture types, 9 face texture types). Rebuild (`build_meta_human`) deferred to the body-refit step so it only runs once.
