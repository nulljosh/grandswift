"""Build a black short-sleeve polo that fits Joshua's MetaHuman body and skins to the same armature.
Headless: /Applications/Blender.app/Contents/MacOS/Blender -b --python unreal/polo.py
Reads unreal/assets/joshua_body.fbx, writes unreal/assets/polo.fbx plus front/side/posed
verification renders. Everything below is in the body's own local space (cm), same as the
source FBX bone rest positions -- object world matrices carry the cm->m scale, so mesh
vertex coords and armature bone head_local/tail_local numbers are directly comparable.
"""
import bpy, bmesh, math, os
from mathutils import Vector, kdtree

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BODY_FBX = os.path.join(REPO, "unreal/assets/joshua_body.fbx")
POLO_FBX = os.path.join(REPO, "unreal/assets/polo.fbx")
OUT_FRONT = os.path.join(REPO, "unreal/assets/polo_front.png")
OUT_SIDE = os.path.join(REPO, "unreal/assets/polo_side.png")
OUT_POSED = os.path.join(REPO, "unreal/assets/polo_posed.png")

# ---- tunables (cm, body local space) --------------------------------------------------
HEM_Z = 79.0                 # hip-length hem
NECK_CUT_Z = 137.5           # torso mesh stops here, collar geometry added above
TORSO_RADIUS = 27.0          # max horizontal dist from spine axis kept as "torso"
SLEEVE_T_MAX = 0.55          # fraction of shoulder->elbow kept as sleeve (short sleeve)
SLEEVE_RADIUS = 13.0         # max dist from upperarm bone axis kept as "sleeve"
CLOTH_OFFSET = 1.0           # cm, offset outward along normal for cloth thickness
FRONT_SIGN = -1.0            # -Y is front (checked against renders below)

# ---------------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=BODY_FBX)

arm = bpy.data.objects["root"]
body = bpy.data.objects["SKM_Joshua_BodyMesh_LOD1"]

# "SKM_Joshua_BodyMesh" is a wrapper empty carrying the cm->m (0.01) scale; "root" (the
# armature) is parented to it. Bake that scale onto the armature itself and drop the
# wrapper, so the exported hierarchy is a clean armature+mesh with no parent empty.
wrapper = bpy.data.objects.get("SKM_Joshua_BodyMesh")
if wrapper:
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")

# drop the other LODs and empties, keep the scene clean for render + export
for name in ["SKM_Joshua_BodyMesh_LOD0", "SKM_Joshua_BodyMesh_LOD2", "SKM_Joshua_BodyMesh_LOD3",
             "SKM_Joshua_BodyMesh", "SKM_Joshua_BodyMesh_LodGroup"]:
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o, do_unlink=True)

bones = arm.data.bones
def bpos(name, which="head"):
    b = bones[name]
    return (b.head_local if which == "head" else b.tail_local).copy()

spine_axis_xy = Vector((0.0, -2.5))  # rough spine center in XY across torso height

shoulder_l, elbow_l = bpos("upperarm_l", "head"), bpos("lowerarm_l", "head")
shoulder_r, elbow_r = bpos("upperarm_r", "head"), bpos("lowerarm_r", "head")

def sleeve_test(co, shoulder, elbow):
    axis = elbow - shoulder
    L = axis.length
    t = (co - shoulder).dot(axis) / (L * L)
    if t < -0.25 or t > SLEEVE_T_MAX:
        return False
    closest = shoulder + axis * max(0.0, min(1.0, t))
    return (co - closest).length <= SLEEVE_RADIUS

def torso_test(co):
    if co.z < HEM_Z or co.z > NECK_CUT_Z:
        return False
    r = (Vector((co.x, co.y)) - spine_axis_xy).length
    return r <= TORSO_RADIUS

def keep_test(co):
    return torso_test(co) or sleeve_test(co, shoulder_l, elbow_l) or sleeve_test(co, shoulder_r, elbow_r)

# ---- duplicate body -> Polo shell, keep only the torso/sleeve region ------------------
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.duplicate()
polo = bpy.context.active_object
polo.name = "Polo"
polo.data.name = "Polo"

bm = bmesh.new()
bm.from_mesh(polo.data)
bm.verts.ensure_lookup_table()
to_delete = [v for v in bm.verts if not keep_test(v.co)]
bmesh.ops.delete(bm, geom=to_delete, context="VERTS")
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001)
bm.normal_update()

# ---- offset outward along vertex normal for cloth thickness ---------------------------
for v in bm.verts:
    v.co += v.normal * CLOTH_OFFSET

# ---- collect boundary loops (hem / neck / sleeve_l / sleeve_r) before adding collar ----
boundary_edges = [e for e in bm.edges if e.is_boundary]
visited = set()
loops = []
for e in boundary_edges:
    if e in visited:
        continue
    group = set()
    stack = [e]
    while stack:
        cur = stack.pop()
        if cur in group:
            continue
        group.add(cur)
        for v in cur.verts:
            for e2 in v.link_edges:
                if e2.is_boundary and e2 not in group:
                    stack.append(e2)
    visited |= group
    loops.append(group)

def loop_centroid(edges):
    vs = set()
    for e in edges:
        vs.update(e.verts)
    c = Vector((0, 0, 0))
    for v in vs:
        c += v.co
    return c / len(vs), vs

neck_loop_edges = None
best_z = -1e9
for grp in loops:
    c, vs = loop_centroid(grp)
    if c.z > best_z:
        best_z = c.z
        neck_loop_edges = grp

vs0 = set()
for e in neck_loop_edges:
    vs0.update(e.verts)
center = sum((v.co for v in vs0), Vector((0, 0, 0))) / len(vs0)

def radial_out(co):
    out = Vector((co.x - center.x, co.y - center.y, 0.0))
    if out.length > 1e-6:
        out.normalize()
    return out

def extrude_ring(edges, offset_fn):
    """Extrude a boundary edge loop into a connected face strip, offset the new rim."""
    ext = bmesh.ops.extrude_edge_only(bm, edges=list(edges))
    geom = ext["geom"]
    new_verts = [g for g in geom if isinstance(g, bmesh.types.BMVert)]
    new_edges = [g for g in geom if isinstance(g, bmesh.types.BMEdge)]
    nv_set = set(new_verts)
    far_edges = [e for e in new_edges if e.verts[0] in nv_set and e.verts[1] in nv_set]
    for v in new_verts:
        v.co = offset_fn(v.co)
    return new_verts, far_edges

# ---- build a folded polo collar on the neck loop: a short stand, then a flap that
# folds outward and slightly down, like a real polo collar -----------------------------
# a single ring keeps the collar band manifold and well-weighted; a second folded-out
# ring pinched at the shoulder corners (where the neck loop is sharply non-circular) and
# that pinch tore open under a pose, so the collar stays a simple raised stand.
extrude_ring(neck_loop_edges, lambda co: co + Vector((0, 0, 1.0)) + radial_out(co) * 0.5)

# ---- placket: 3-button strip at the front of the neck ----------------------------------
# anchor it to the real chest surface (sampled from the body mesh) instead of a guessed
# offset, so it clears the pec bulge instead of sinking into it. Built directly as bmesh
# geometry (not separate scene objects) so it shares Polo's own local coordinate space --
# separate objects created at these raw-cm coordinates have no parent transform and end
# up 100x too big/far away once joined into a 0.01-scaled hierarchy.
def front_surface_y(z, x=0.0, win=3.0):
    best = None
    for v in body.data.vertices:
        if abs(v.co.x - x) < win and abs(v.co.z - z) < win:
            if best is None or (FRONT_SIGN > 0 and v.co.y > best) or (FRONT_SIGN < 0 and v.co.y < best):
                best = v.co.y
    return best if best is not None else spine_axis_xy.y

def add_box(center, size):
    ret = bmesh.ops.create_cube(bm, size=1.0)
    verts = ret["verts"]
    bmesh.ops.scale(bm, vec=size, verts=verts)
    bmesh.ops.translate(bm, vec=center, verts=verts)
    return verts

placket_z = NECK_CUT_Z - 8.0
placket_y = front_surface_y(placket_z) + FRONT_SIGN * 2.4
add_box(Vector((0.0, placket_y, placket_z)), Vector((1.6, 0.5, 8.0)))

for i in range(3):
    bz = NECK_CUT_Z - 5.0 - i * 3.5
    by = front_surface_y(bz) + FRONT_SIGN * 2.7
    add_box(Vector((0.0, by, bz)), Vector((0.9, 0.7, 0.9)))

bm.normal_update()
bm.to_mesh(polo.data)
bm.free()
polo.data.update()

# ---- material: near-black cotton -------------------------------------------------------
mat = bpy.data.materials.new("Polo")
mat.use_nodes = True
bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1.0)
bsdf.inputs["Roughness"].default_value = 0.8
polo.data.materials.clear()
polo.data.materials.append(mat)

# ---- smooth: subdivide once and apply so it reads as fabric, not skin -----------------
subsurf = polo.modifiers.new("Smooth", type="SUBSURF")
subsurf.levels = 1
subsurf.render_levels = 1
bpy.context.view_layer.objects.active = polo
bpy.ops.object.modifier_apply(modifier=subsurf.name)
bpy.ops.object.shade_smooth()

# ---- skin to the SAME armature: Data Transfer weights from the body, then Armature ----
dt = polo.modifiers.new("WeightTransfer", type="DATA_TRANSFER")
dt.object = body
dt.use_vert_data = True
dt.data_types_verts = {"VGROUP_WEIGHTS"}
dt.vert_mapping = "POLYINTERP_NEAREST"
dt.layers_vgroup_select_src = "ALL"
dt.layers_vgroup_select_dst = "NAME"
dt.mix_mode = "REPLACE"
bpy.context.view_layer.objects.active = polo
bpy.ops.object.datalayout_transfer(modifier=dt.name)
bpy.ops.object.modifier_apply(modifier=dt.name)

# nearest-face weight transfer is unreliable for vertices that sit far from the source
# body surface -- mainly the collar stand/fold and the placket/buttons, which are 1.5-4cm
# proud of the skin. Those can pick up a wrong (or zero) nearest-face weight, so they sit
# frozen in bind pose while their neighbors deform under a pose, reading as a torn seam.
# Fix: any polo vertex farther than 1.3cm from the nearest body vertex, or with no weight
# at all, clones the full weight set from its nearest *good* polo vertex instead.
verts = polo.data.vertices
totals = [0.0] * len(verts)
for vg in polo.vertex_groups:
    for i in range(len(verts)):
        try:
            totals[i] += vg.weight(i)
        except RuntimeError:
            pass

body_kd = kdtree.KDTree(len(body.data.vertices))
for i, v in enumerate(body.data.vertices):
    body_kd.insert(v.co, i)
body_kd.balance()

FAR_THRESHOLD = 1.3
good, bad = [], []
for i, v in enumerate(verts):
    _, _, dist = body_kd.find(v.co)
    (bad if (dist > FAR_THRESHOLD or totals[i] <= 1e-6) else good).append(i)
print("verts needing weight fix (far from skin or zero weight):", len(bad), "/", len(verts))

if bad and good:
    kd = kdtree.KDTree(len(good))
    for j, i in enumerate(good):
        kd.insert(verts[i].co, j)
    kd.balance()
    for i in bad:
        _, j, _ = kd.find(verts[i].co)
        src = good[j]
        for vg in polo.vertex_groups:
            try:
                w = vg.weight(src)
            except RuntimeError:
                continue
            vg.add([i], w, "REPLACE")

# nearest-face transfer is also rigid right at region boundaries (e.g. the shoulder
# seam between torso and sleeve): a vertex can end up ~100% clavicle right next to one
# that's ~100% upperarm. Smooth all vertex groups across the surface to blend those
# hard edges before skinning.
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=4)
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.vertex_group_normalize_all(lock_active=False)

polo.parent = body.parent
polo.matrix_parent_inverse = body.matrix_parent_inverse.copy()

armmod = polo.modifiers.new("root", type="ARMATURE")
armmod.object = arm
armmod.use_vertex_groups = True
armmod.use_deform_preserve_volume = True  # dual quaternion skinning: far less joint collapse/tear than linear blend

# approximated cloth weights (copied/smoothed from the body's own weights, which were
# hand-sculpted for a much harder region -- the shoulder saddle) still diverge from the
# body's real deformation enough, at a full 45 degree rotation, to let skin show through
# right at that saddle. Corrective Smooth relaxes the POSED mesh back toward its bound
# rest shape, which is the standard fix for this class of skinning artifact.
csmod = polo.modifiers.new("CorrectiveSmooth", type="CORRECTIVE_SMOOTH")
csmod.factor = 1.0
csmod.iterations = 12
csmod.smooth_type = "LENGTH_WEIGHTED"
csmod.rest_source = "BIND"
bpy.context.view_layer.objects.active = polo
bpy.ops.object.correctivesmooth_bind(modifier=csmod.name)

print("polo verts:", len(polo.data.vertices), "vgroups:", len(polo.vertex_groups))

# ---- render setup ------------------------------------------------------------------
# give the body a plain skin tone for these verification renders only (its real baked
# material has no texture loaded here) so the black polo reads clearly against it
skin_mat = bpy.data.materials.new("SkinPreview")
skin_mat.use_nodes = True
skin_bsdf = next(n for n in skin_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
skin_bsdf.inputs["Base Color"].default_value = (0.75, 0.57, 0.48, 1.0)
skin_bsdf.inputs["Roughness"].default_value = 0.6
body.data.materials.clear()
body.data.materials.append(skin_mat)

scene = bpy.context.scene
engine_items = [i.identifier for i in scene.render.bl_rna.properties["engine"].enum_items]
for cand in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    if cand in engine_items:
        scene.render.engine = cand
        break
scene.render.resolution_x = 900
scene.render.resolution_y = 1200
scene.render.film_transparent = False
if hasattr(scene, "world") and scene.world is None:
    scene.world = bpy.data.worlds.new("World")
scene.world.use_nodes = True
bg = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.72, 0.75, 0.8, 1.0)
bg.inputs["Strength"].default_value = 1.1

sun_data = bpy.data.lights.new("Sun", type="SUN")
sun_data.energy = 3.0
sun = bpy.data.objects.new("Sun", sun_data)
bpy.context.collection.objects.link(sun)
sun.rotation_euler = (math.radians(55), 0, math.radians(35))

fill_data = bpy.data.lights.new("Fill", type="SUN")
fill_data.energy = 1.2
fill = bpy.data.objects.new("Fill", fill_data)
bpy.context.collection.objects.link(fill)
fill.rotation_euler = (math.radians(60), 0, math.radians(-140))

cam_data = bpy.data.cameras.new("Cam")
cam_data.lens = 50
cam = bpy.data.objects.new("Cam", cam_data)
bpy.context.collection.objects.link(cam)
scene.camera = cam

target = Vector((0, 0, 1.05))

def point_camera(loc):
    cam.location = loc
    direction = target - loc
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

def render(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("rendered", path)

point_camera(Vector((0, FRONT_SIGN * 1.7, 1.05)))
render(OUT_FRONT)

point_camera(Vector((1.7, 0, 1.05)))
render(OUT_SIDE)

# ---- posed check: rotate upperarm_l 45deg, confirm sleeve follows ----------------------
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
pb = arm.pose.bones["upperarm_l"]
pb.rotation_mode = "XYZ"
pb.rotation_euler = (math.radians(45.0), 0.0, 0.0)
bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode="OBJECT")

point_camera(Vector((0, FRONT_SIGN * 1.7, 1.05)))
render(OUT_POSED)

# ---- export skeletal mesh (armature + polo, deform bones only, no leaf bones) ---------
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
polo.select_set(True)
bpy.context.view_layer.objects.active = polo

bpy.ops.export_scene.fbx(
    filepath=POLO_FBX,
    use_selection=True,
    object_types={"ARMATURE", "MESH"},
    add_leaf_bones=False,
    use_armature_deform_only=True,
    bake_anim=False,
    mesh_smooth_type="FACE",
    use_mesh_modifiers=True,
)
print("exported", POLO_FBX)
