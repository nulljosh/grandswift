import bpy, math
bpy.ops.wm.read_factory_settings(use_empty=True)
def mat(n, c):
    m = bpy.data.materials.new(n); m.diffuse_color = c; return m
FR, LE, RV = mat("Frame", (0.08, 0.03, 0.01, 1)), mat("Lens", (0.9, 0.95, 1, 0.1)), mat("Rivet", (0.8, 0.8, 0.8, 1))
objs = []
def rim(x):
    bpy.ops.curve.primitive_bezier_circle_add(radius=0.025, location=(x, 0, 0), rotation=(math.pi/2, 0, 0))
    c = bpy.context.object; c.scale = (1.0, 0.87, 1.0)  # panto: a touch shorter than wide
    bpy.ops.object.transform_apply(scale=True)
    c.data.bevel_depth = 0.0015; c.data.extrude = 0.0009; c.data.bevel_resolution = 3; c.data.resolution_u = 24
    bpy.ops.object.convert(target='MESH'); c.data.materials.append(FR); objs.append(c)
    bpy.ops.mesh.primitive_circle_add(vertices=48, radius=0.0245, fill_type='NGON', location=(x, 0.0005, 0), rotation=(math.pi/2, 0, 0))
    l = bpy.context.object; l.scale = (1.0, 0.9, 1.0); l.data.materials.append(LE); objs.append(l)
for x in (-0.0335, 0.0335): rim(x)
# keyhole bridge: an arch over the nose
bpy.ops.curve.primitive_bezier_curve_add(location=(0, 0, 0))
b = bpy.context.object; p = b.data.splines[0].bezier_points
p[0].co, p[1].co = (-0.0095, 0, 0.012), (0.0095, 0, 0.012)
p[0].handle_right, p[1].handle_left = (-0.004, 0, 0.019), (0.004, 0, 0.019)
p[0].handle_left, p[1].handle_right = (-0.012, 0, 0.010), (0.012, 0, 0.010)
b.data.bevel_depth = 0.0015; b.data.extrude = 0.001
bpy.ops.object.convert(target='MESH'); b.data.materials.append(FR); objs.append(b)
for s in (-1, 1):
    # hinge block and temple arm running back to the ear
    bpy.ops.mesh.primitive_cube_add(size=1, location=(s*0.0595, 0.004, 0.012)); h = bpy.context.object; h.scale = (0.006, 0.008, 0.007); h.data.materials.append(FR); objs.append(h)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(s*0.0615, 0.075, 0.012)); t = bpy.context.object; t.scale = (0.0018, 0.14, 0.004); t.data.materials.append(FR); objs.append(t)
    for dx in (0.0, 0.0045):  # the two silver rivets on each front corner
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.0009, location=(s*(0.051 - dx), -0.0035, 0.014)); r = bpy.context.object; r.data.materials.append(RV); objs.append(r)
bpy.ops.object.select_all(action='DESELECT')
for o in objs: o.select_set(True)
bpy.context.view_layer.objects.active = objs[0]; bpy.ops.object.join()
o = bpy.context.object; o.name = "SM_Glasses"
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath="/Users/joshua/Documents/Code/vancouvervice/unreal/assets/glasses.fbx", use_selection=True)
print("GLASSES OK", [m.name for m in o.data.materials])
