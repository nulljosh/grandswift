import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)

# Create materials
mat_body = bpy.data.materials.new("DrivePlastic")
mat_body.diffuse_color = (0.15, 0.15, 0.17, 1.0)  # Dark grey/black

mat_led = bpy.data.materials.new("LED")
mat_led.diffuse_color = (0.2, 0.8, 0.2, 1.0)  # Green LED indicator

mat_connector = bpy.data.materials.new("Connector")
mat_connector.diffuse_color = (0.3, 0.3, 0.32, 1.0)  # Slightly lighter metal

objs = []

# Main drive body: 0.13m x 0.08m x 0.02m
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.object
body.scale = (0.065, 0.04, 0.01)
body.data.materials.append(mat_body)

# Add slight bevel for rounded edges
bevel = body.modifiers.new(name="Bevel", type='BEVEL')
bevel.width = 0.002
bevel.segments = 2

objs.append(body)

# Small LED indicator on front face
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.002, location=(0.05, 0.025, 0.011))
led = bpy.context.object
led.data.materials.append(mat_led)
objs.append(led)

# USB connector port (small rectangular protrusion on one side)
bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.07, 0, 0.005))
connector = bpy.context.object
connector.scale = (0.008, 0.012, 0.004)
connector.data.materials.append(mat_connector)
objs.append(connector)

# Join all objects
bpy.ops.object.select_all(action='DESELECT')
for o in objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
bpy.ops.object.join()

obj = bpy.context.object
obj.name = "SM_HardDrive"
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath="/Users/joshua/Documents/Code/vancouvervice/unreal/assets/harddrive.fbx", use_selection=True)
print("HARDDRIVE OK")
