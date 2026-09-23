import bpy, math, json, mathutils

FACE_FBX = "/Users/joshua/Documents/Code/vancouvervice/unreal/assets/joshua_face.fbx"
OUT_FBX = "/Users/joshua/Documents/Code/vancouvervice/unreal/assets/glasses_fit.fbx"
OUT_JSON = "/Users/joshua/Documents/Code/vancouvervice/unreal/assets/glasses_fit.json"
OUT_FRONT_PNG = "/Users/joshua/Documents/Code/vancouvervice/unreal/assets/glasses_fit_front.png"
OUT_34_PNG = "/Users/joshua/Documents/Code/vancouvervice/unreal/assets/glasses_fit_34.png"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FACE_FBX)

face_obj = bpy.data.objects["SKM_Joshua_FaceMesh_LOD0"]
arm = bpy.data.objects["root"]
for o in list(bpy.data.objects):
    if o.type == 'MESH' and o.name != face_obj.name:
        bpy.data.objects.remove(o, do_unlink=True)

def bone_head_m(name):
    return arm.data.bones[name].head_local * 0.01

eyeL = bone_head_m("FACIAL_L_Eye")
eyeR = bone_head_m("FACIAL_R_Eye")
headb = bone_head_m("head")

depsgraph = bpy.context.evaluated_depsgraph_get()
obj_eval = face_obj.evaluated_get(depsgraph)
mesh_eval = obj_eval.to_mesh()
verts_world = [face_obj.matrix_world @ v.co for v in mesh_eval.vertices]

def frontmost_near(cx, cz, xr=0.012, zr=0.01):
    best = None
    for v in verts_world:
        if abs(v.x - cx) < xr and abs(v.z - cz) < zr:
            if best is None or v.y < best.y:
                best = v
    return best

fL = frontmost_near(eyeL.x, eyeL.z)
fR = frontmost_near(eyeR.x, eyeR.z)
eye_surface_y = (fL.y + fR.y) / 2.0

# nose bridge (nasion): most-recessed point (max y, least negative) at x~0 between eye height and 1.5cm above
best_nasion = None
for v in verts_world:
    if abs(v.x) < 0.006 and 1.605 <= v.z <= 1.635 and v.y < -0.05:
        if best_nasion is None or v.y > best_nasion.y:
            best_nasion = v
nosebridge = best_nasion

half_width = max(abs(v.x) for v in verts_world if abs(v.z - headb.z) < 0.004)

# ear tips: widest point of the head silhouette near mid-depth (y close to 0), around eye height
ear_cand = [v for v in verts_world if 1.55 <= v.z <= 1.65 and -0.03 <= v.y <= 0.03]
ear_left = max(ear_cand, key=lambda v: v.x)   # character's left ear (+x)
ear_right = min(ear_cand, key=lambda v: v.x)  # character's right ear (-x)

obj_eval.to_mesh_clear()

print("=== LANDMARKS (m, face-mesh bind pose space) ===")
print("eyeL center (bone):", tuple(round(c, 5) for c in eyeL))
print("eyeR center (bone):", tuple(round(c, 5) for c in eyeR))
print("eye surface (frontmost near eyes, avg y):", round(eye_surface_y, 5))
print("nose bridge / nasion surface point:", tuple(round(c, 5) for c in nosebridge))
print("head width half at head-bone z:", round(half_width, 5))
print("ear left (char left):", tuple(round(c, 5) for c in ear_left))
print("ear right (char right):", tuple(round(c, 5) for c in ear_right))
print("head bone world:", tuple(round(c, 5) for c in headb))

# ---- glasses geometry ----
eye_z = (eyeL.z + eyeR.z) / 2.0
front_y = eye_surface_y - 0.010          # front rim plane: 1cm in front of eye/brow surface
lens_w, lens_h = 0.050, 0.044
rim_r = lens_w / 2.0
squish = lens_h / lens_w                  # ~0.88, panto shape

def mat(n, c, alpha=1.0, metallic=0.0, roughness=0.35, blend=False):
    m = bpy.data.materials.new(n)
    m.diffuse_color = c
    m.use_nodes = True
    bsdf = next(nd for nd in m.node_tree.nodes if nd.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = c
    if 'Alpha' in bsdf.inputs:
        bsdf.inputs['Alpha'].default_value = alpha
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = metallic
    if 'Roughness' in bsdf.inputs:
        bsdf.inputs['Roughness'].default_value = roughness
    if blend:
        m.blend_method = 'BLEND'
        try:
            m.show_transparent_back = False
        except AttributeError:
            pass
    return m

FR = mat("Frame", (0.07, 0.03, 0.01, 1), alpha=1.0, metallic=0.0, roughness=0.3)
LE = mat("Lens", (0.85, 0.94, 1.0, 1.0), alpha=0.18, roughness=0.05, blend=True)
RV = mat("Rivet", (0.75, 0.75, 0.78, 1), alpha=1.0, metallic=0.9, roughness=0.25)

objs = []

def rim(cx, cz):
    bpy.ops.curve.primitive_bezier_circle_add(radius=rim_r, location=(cx, front_y, cz), rotation=(math.pi / 2, 0, 0))
    c = bpy.context.object
    c.scale = (1.0, squish, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    c.data.bevel_depth = 0.0015
    c.data.extrude = 0.0009
    c.data.bevel_resolution = 3
    c.data.resolution_u = 24
    bpy.ops.object.convert(target='MESH')
    c.data.materials.append(FR)
    objs.append(c)
    bpy.ops.mesh.primitive_circle_add(vertices=48, radius=rim_r - 0.0005, fill_type='NGON',
                                       location=(cx, front_y + 0.0005, cz), rotation=(math.pi / 2, 0, 0))
    l = bpy.context.object
    l.scale = (1.0, squish + 0.03, 1.0)
    l.data.materials.append(LE)
    objs.append(l)

rim(eyeL.x, eye_z)
rim(eyeR.x, eye_z)

# keyhole bridge: arch from the inner-top of each rim down to the nasion point on the nose
inner_l = eyeL.x - rim_r * 0.9
inner_r = eyeR.x + rim_r * 0.9
top_z = eye_z + rim_r * squish * 0.55
bridge_z = nosebridge.z
bridge_y = nosebridge.y + 0.0015  # sit just in front of the skin

bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, 0))
b = bpy.context.object
p = b.data.splines[0].bezier_points
p[0].co = (inner_r, front_y, top_z)
p[1].co = (inner_l, front_y, top_z)
p[0].handle_right = (inner_r * 0.5, bridge_y, top_z - 0.001)
p[1].handle_left = (inner_l * 0.5, bridge_y, top_z - 0.001)
p[0].handle_left = (inner_r * 1.3, front_y, top_z + 0.001)
p[1].handle_right = (inner_l * 1.3, front_y, top_z + 0.001)
b.data.bevel_depth = 0.0015
b.data.extrude = 0.001
bpy.ops.object.convert(target='MESH')
b.data.materials.append(FR)
objs.append(b)

def box_between(a, b, width, thick, material):
    """A rectangular box (cross-section width x thick) running from point a to point b."""
    a = mathutils.Vector(a)
    b = mathutils.Vector(b)
    mid = (a + b) / 2.0
    length = (b - a).length
    bpy.ops.mesh.primitive_cube_add(size=1, location=mid)
    obj = bpy.context.object
    obj.scale = (width, length, thick)
    direction = (b - a).normalized()
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = direction.to_track_quat('Y', 'Z')
    obj.data.materials.append(material)
    return obj

# hinges + temples running from the outer rim corner straight back to the actual ear tip
for s, ear_pt in ((1, ear_left), (-1, ear_right)):
    outer_x = eyeL.x + rim_r if s > 0 else eyeR.x - rim_r
    hinge_pt = mathutils.Vector((outer_x + s * 0.002, front_y + 0.002, eye_z))

    bpy.ops.mesh.primitive_cube_add(size=1, location=hinge_pt)
    h = bpy.context.object
    h.scale = (0.006, 0.008, 0.007)
    h.data.materials.append(FR)
    objs.append(h)

    temple_end = mathutils.Vector((ear_pt.x, ear_pt.y + 0.006, ear_pt.z))  # hook just in front of the ear
    t = box_between(hinge_pt, temple_end, 0.0018, 0.004, FR)
    objs.append(t)

    for dz in (-0.003, 0.003):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0009, location=(hinge_pt.x, hinge_pt.y - 0.001, eye_z + dz))
        r = bpy.context.object
        r.data.materials.append(RV)
        objs.append(r)

bpy.ops.object.select_all(action='DESELECT')
for o in objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
bpy.ops.object.join()
glasses_obj = bpy.context.object
glasses_obj.name = "SM_Glasses_Fit"
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# glasses "origin" for the offset = midpoint between lens centres, on the front plane
glasses_origin = mathutils.Vector(((eyeL.x + eyeR.x) / 2.0, front_y, eye_z))

bpy.ops.object.select_all(action='DESELECT')
glasses_obj.select_set(True)
bpy.context.view_layer.objects.active = glasses_obj
bpy.ops.export_scene.fbx(filepath=OUT_FBX, use_selection=True)
print("GLASSES OK", [m.name for m in glasses_obj.data.materials])

# ---- head-bone-relative offset, cm, UE convention ----
# The FBX roundtrip that produced joshua_face.fbx applies a pure uniform scale (0.01) with
# zero rotation from bone-local (UE, cm) space to this Blender world (m) space -- confirmed by
# inspecting the armature's world matrix (identity rotation, scale 0.01 on all axes). So the
# offset below is a straight (world - head_bone) * 100 with no axis remap, rotation = zero.
offset_m = glasses_origin - headb
offset_cm = tuple(round(c * 100.0, 3) for c in offset_m)

data = {
    "note": "Offset of glasses origin relative to the 'head' bone's bind-pose transform, in the head bone's local axes (cm). Rotation is zero: the glasses were modeled axis-aligned to the same frame as joshua_face.fbx, so no additional pitch/yaw/roll is needed when attaching to the head socket.",
    "location_cm": {"x": offset_cm[0], "y": offset_cm[1], "z": offset_cm[2]},
    "rotation_deg": {"pitch": 0.0, "yaw": 0.0, "roll": 0.0},
    "landmarks_m": {
        "eyeL_center": [round(c, 5) for c in eyeL],
        "eyeR_center": [round(c, 5) for c in eyeR],
        "eye_surface_y": round(eye_surface_y, 5),
        "nose_bridge": [round(c, 5) for c in nosebridge],
        "head_bone": [round(c, 5) for c in headb],
        "glasses_origin": [round(c, 5) for c in glasses_origin],
        "head_width_half_at_eye_level": round(half_width, 5),
    },
}
with open(OUT_JSON, "w") as f:
    json.dump(data, f, indent=2)
print("JSON OK", data["location_cm"], data["rotation_deg"])

# give the face a simple skin material so the fit is easy to read in the render
skin = bpy.data.materials.new("Skin")
skin.use_nodes = True
skin_bsdf = next(nd for nd in skin.node_tree.nodes if nd.type == 'BSDF_PRINCIPLED')
skin_bsdf.inputs['Base Color'].default_value = (0.82, 0.63, 0.52, 1)
skin_bsdf.inputs['Roughness'].default_value = 0.55
face_obj.data.materials.clear()
face_obj.data.materials.append(skin)

# ---- render verification ----
sun = bpy.data.lights.new("Sun", type='SUN')
sun.energy = 2.5
sun_obj = bpy.data.objects.new("Sun", sun)
bpy.context.collection.objects.link(sun_obj)
sun_obj.location = (0.3, -0.5, 2.0)
sun_obj.rotation_euler = (math.radians(60), 0, math.radians(30))

fill = bpy.data.lights.new("Fill", type='AREA')
fill.energy = 4.0
fill.size = 0.3
fill_obj = bpy.data.objects.new("Fill", fill)
bpy.context.collection.objects.link(fill_obj)
fill_obj.location = (-0.2, -0.4, eye_z)
fill_obj.rotation_euler = (math.radians(90), 0, math.radians(-25))

scene_view = bpy.context.scene.view_settings
scene_view.view_transform = 'Standard'

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in [e.identifier for e in scene.render.bl_rna.properties['engine'].enum_items] else scene.render.engine
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new("World")
scene.world.use_nodes = True
bg = next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND')
bg.inputs[0].default_value = (0.5, 0.55, 0.6, 1)

cam_data = bpy.data.cameras.new("Cam")
cam_data.lens = 85
cam_obj = bpy.data.objects.new("Cam", cam_data)
bpy.context.collection.objects.link(cam_obj)
scene.camera = cam_obj

target = mathutils.Vector((0.0, eye_z, eye_z))  # placeholder, fixed below
target = mathutils.Vector((0.0, front_y, eye_z))

def look_at(obj, cam_pos, target_pos):
    obj.location = cam_pos
    direction = target_pos - cam_pos
    rot_quat = direction.to_track_quat('-Z', 'Y')
    obj.rotation_euler = rot_quat.to_euler()

# front view: camera straight ahead of the face
look_at(cam_obj, mathutils.Vector((0.0, front_y - 0.45, eye_z)), target)
bpy.context.view_layer.update()
scene.render.filepath = OUT_FRONT_PNG
bpy.ops.render.render(write_still=True)
print("RENDER FRONT OK")

# 3/4 view
look_at(cam_obj, mathutils.Vector((0.28, front_y - 0.38, eye_z + 0.03)), target)
bpy.context.view_layer.update()
scene.render.filepath = OUT_34_PNG
bpy.ops.render.render(write_still=True)
print("RENDER 3/4 OK")

print("DONE")
