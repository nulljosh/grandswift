# Runs inside the editor during Play. Walks the real character through waypoints (metres from spawn), then reports.
import unreal, math
if "QA" in globals() and QA.get("h"):
    unreal.unregister_slate_post_tick_callback(QA["h"])  # never stack two drivers
world = unreal.UnrealEditorSubsystem().get_game_world()
pawn = unreal.GameplayStatics.get_player_pawn(world, 0)
start = pawn.get_actor_location()
ROUTE = [(20, 0), (20, 20), (0, 20), (0, 0)]  # a 20 m square
QA = {"i": 0, "t": 0.0, "leg": 0.0, "min_z": start.z, "hits": 0}
QA_RESULT = "RUNNING"

def _finish(msg):
    global QA_RESULT
    unreal.unregister_slate_post_tick_callback(QA["h"]); QA["h"] = None
    QA_RESULT = msg

def _step(dt):
    if not unreal.UnrealEditorSubsystem().get_game_world():
        return _finish("FAIL play stopped mid-test")
    QA["t"] += dt; QA["leg"] += dt
    p = pawn.get_actor_location(); QA["min_z"] = min(QA["min_z"], p.z)
    if QA["min_z"] < start.z - 1000:
        return _finish(f"FAIL fell through the street at {p.x:.0f},{p.y:.0f},{p.z:.0f}")
    tx, ty = ROUTE[QA["i"]]
    dx, dy = start.x + tx * 100 - p.x, start.y + ty * 100 - p.y
    d = math.hypot(dx, dy)
    if d < 150:
        QA["hits"] += 1; QA["i"] += 1; QA["leg"] = 0.0
        if QA["i"] == len(ROUTE):
            return _finish(f"PASS walked {len(ROUTE)} waypoints in {QA['t']:.0f}s, lowest z {QA['min_z']:.0f}")
        return
    if QA["leg"] > 20:
        return _finish(f"FAIL stuck {d/100:.1f} m from waypoint {QA['i']} after {QA['hits']} reached")
    pawn.add_movement_input(unreal.Vector(dx / d, dy / d, 0), 1.0)

QA["h"] = unreal.register_slate_post_tick_callback(_step)
print("walking from", start)
