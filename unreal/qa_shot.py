# Runs inside the editor during Play. Photo booth: waits for the city to stream in, parks a camera on the
# street looking at Joshua from a spot with a clear line of sight, takes one HighResShot, gives the view back.
# Result: QA_RESULT = "PASS shot <name>" or "FAIL <why>". Name comes from SHOT_NAME if set, else joshua.
import unreal, math
if "QA" in globals() and QA.get("h"):
    unreal.unregister_slate_post_tick_callback(QA["h"])
world = unreal.UnrealEditorSubsystem().get_game_world()
pawn = unreal.GameplayStatics.get_player_pawn(world, 0)
pc = unreal.GameplayStatics.get_player_controller(world, 0)
tiles = unreal.GameplayStatics.get_actor_of_class(world, unreal.Cesium3DTileset)
NAME = globals().get("SHOT_NAME", "joshua")
QA = {"t": 0.0, "phase": "load", "cam": None}
QA_RESULT = "RUNNING"

def _finish(msg):
    global QA_RESULT
    unreal.unregister_slate_post_tick_callback(QA["h"]); QA["h"] = None
    if QA["cam"]:
        pc.set_view_target_with_blend(pawn, 0.0); QA["cam"].destroy_actor()
    QA_RESULT = msg

def _clear(a, b):
    # ponytail: one line trace; good enough to keep the camera out of buildings
    hit = unreal.SystemLibrary.line_trace_single(world, a, b, unreal.TraceTypeQuery.TRACE_TYPE_QUERY1, False, [pawn], unreal.DrawDebugTrace.NONE, True)
    return not hit or not hit.to_tuple()[0]

def _place():
    loc = pawn.get_actor_location(); rot = pawn.get_actor_rotation()
    f = rot.get_forward_vector(); r = rot.get_right_vector()
    eye = loc + unreal.Vector(0, 0, 60)
    for fx, rx in [(1, 0.6), (1, -0.6), (1, 0), (-1, 0.6), (0, 1), (0, -1)]:  # front three-quarter first, then anything clear
        cam_loc = loc + f * (320 * fx) + r * (320 * rx) + unreal.Vector(0, 0, 140)
        if _clear(cam_loc, eye):
            cam = world.spawn_actor_from_class(unreal.CameraActor, cam_loc, unreal.MathLibrary.find_look_at_rotation(cam_loc, eye))
            cam.get_camera_component().set_editor_property("field_of_view", 55.0)
            pc.set_view_target_with_blend(cam, 0.0)
            return cam
    return None

def _step(dt):
    if not unreal.UnrealEditorSubsystem().get_game_world():
        return _finish("FAIL play stopped mid-shot")
    QA["t"] += dt
    if QA["phase"] == "load":
        prog = tiles.get_load_progress() if tiles else 100.0
        if prog >= 95 or QA["t"] > 45:
            QA["cam"] = _place()
            if not QA["cam"]:
                return _finish("FAIL no clear spot to put the camera")
            QA["phase"] = "settle"; QA["t"] = 0.0
    elif QA["phase"] == "settle" and QA["t"] > 3:  # let the new view stream textures in
        unreal.SystemLibrary.execute_console_command(world, f"HighResShot 1920x1080 filename={NAME}")
        QA["phase"] = "done"; QA["t"] = 0.0
    elif QA["phase"] == "done" and QA["t"] > 2:
        return _finish(f"PASS shot {NAME} (tiles {tiles.get_load_progress() if tiles else 0:.0f}%)")

QA["h"] = unreal.register_slate_post_tick_callback(_step)
print("photo booth armed")
