# Runs inside the editor during Play. Walks up to the getaway car, presses E, holds W for 6 s through Enhanced Input
# injection (the same path a real keypress takes), presses E again to get out, then reports.
# Starts BP_Missions on mission two (jack a car) and checks it completes once the player is in the car.
import unreal
if "DRIVE" in globals() and DRIVE.get("h"):
    unreal.unregister_slate_post_tick_callback(DRIVE["h"])
world = unreal.UnrealEditorSubsystem().get_game_world()
pc = unreal.GameplayStatics.get_player_controller(world, 0)
sub = [o for o in unreal.ObjectIterator(unreal.EnhancedInputLocalPlayerSubsystem) if o.get_world() == world][0]  # Python has no local-player subsystem getter
EnterCar = unreal.load_asset("/Game/Input/IA_EnterCar")
Throttle = unreal.load_asset("/Game/VehicleTemplate/Input/Actions/IA_Throttle")
car = unreal.GameplayStatics.get_actor_of_class(world, unreal.load_asset("/Game/VehicleTemplate/Blueprints/SportsCar/BP_VehicleAdvSportsCar").generated_class())
walker = pc.get_controlled_pawn()
MISSIONS = unreal.GameplayStatics.get_actor_of_class(world, unreal.load_asset("/Game/VancouverVice/BP_Missions").generated_class())
T0 = MISSIONS.get_editor_property("Targets")[0]
walker.set_actor_location(unreal.Vector(T0.x, T0.y, walker.get_actor_location().z + 50), False, True)  # finish mission one on the spot
DRIVE = {"t": 0.0, "stage": "mission1", "start": None}
QA_RESULT = "RUNNING"

def press(action, value=1.0):
    sub.inject_input_vector_for_action(action, unreal.Vector(value, 0, 0), [], [])

def _finish(msg):
    global QA_RESULT
    unreal.unregister_slate_post_tick_callback(DRIVE["h"]); DRIVE["h"] = None
    QA_RESULT = msg

def _step(dt):
    if not unreal.UnrealEditorSubsystem().get_game_world():
        return _finish("FAIL play stopped mid-test")
    DRIVE["t"] += dt
    if DRIVE["stage"] == "mission1":
        if MISSIONS.get_editor_property("Index") >= 1:
            walker.set_actor_location(car.get_actor_location() + unreal.Vector(0, -300, 120), False, True)
            DRIVE["stage"] = "enter"; DRIVE["t"] = 0.0
        elif DRIVE["t"] > 15:
            return _finish("FAIL mission one never completed at its target")
    elif DRIVE["stage"] == "enter":
        press(EnterCar); DRIVE["stage"] = "wait_in"; DRIVE["t"] = 0.0
    elif DRIVE["stage"] == "wait_in" and DRIVE["t"] > 0.5:
        if pc.get_controlled_pawn() != car:
            return _finish("FAIL E did not put the player in the car")
        DRIVE["stage"] = "drive"; DRIVE["t"] = 0.0; DRIVE["start"] = car.get_actor_location()
    elif DRIVE["stage"] == "drive":
        press(Throttle, 1.0)
        if DRIVE["t"] > 6.0:
            DRIVE["dist"] = (car.get_actor_location() - DRIVE["start"]).length() / 100
            press(EnterCar); DRIVE["stage"] = "wait_out"; DRIVE["t"] = 0.0
    elif DRIVE["stage"] == "wait_out" and DRIVE["t"] > 0.5:
        out = pc.get_controlled_pawn() == walker and not walker.get_editor_property("hidden")
        jacked = MISSIONS.get_editor_property("Index") >= 2
        ok = DRIVE["dist"] > 5 and out and jacked
        return _finish(f"{'PASS' if ok else 'FAIL'} drove {DRIVE['dist']:.1f} m in 6 s, got back out: {out}, mission two complete: {jacked}")

DRIVE["h"] = unreal.register_slate_post_tick_callback(_step)
print("driving test armed")
