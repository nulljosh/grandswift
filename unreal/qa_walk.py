# Runs inside the editor during Play. Drives the real character: run north, turn, jump, run east.
import unreal, math
world = unreal.UnrealEditorSubsystem().get_game_world()
pawn = unreal.GameplayStatics.get_player_pawn(world, 0)
start = pawn.get_actor_location()
QA = {"t": 0.0, "log": [], "min_z": start.z}
QA_RESULT = "RUNNING"
PLAN = [(6, unreal.Vector(1, 0, 0), False), (1, unreal.Vector(1, 0, 0), True), (6, unreal.Vector(0, 1, 0), False), (6, unreal.Vector(-1, 0, 0), False)]

def _step(dt):
    global QA_RESULT
    QA["t"] += dt; t = QA["t"]; acc = 0
    for secs, d, jump in PLAN:
        acc += secs
        if t < acc:
            pawn.add_movement_input(d, 1.0)
            if jump: pawn.jump()
            break
    else:
        unreal.unregister_slate_post_tick_callback(QA["h"])
        end = pawn.get_actor_location()
        moved = math.dist((start.x, start.y), (end.x, end.y)) / 100
        fell = QA["min_z"] < start.z - 1000
        QA_RESULT = ("PASS" if moved > 10 and not fell else "FAIL") + f" moved {moved:.0f} m, lowest z {QA['min_z']:.0f}, start z {start.z:.0f}, end {end.x:.0f},{end.y:.0f},{end.z:.0f}"
        return
    QA["min_z"] = min(QA["min_z"], pawn.get_actor_location().z)

QA["h"] = unreal.register_slate_post_tick_callback(_step)
print("walking from", start)
