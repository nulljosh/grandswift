import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)

# Create material
mat_aluminum = bpy.data.materials.new("Aluminum")
mat_aluminum.diffuse_color = (0.9, 0.9, 0.92, 1.0)  # Silver/aluminum color

# Create a rounded cube for the Mac mini body
# Real dimensions: 197mm x 197mm x 36mm = 0.197 x 0.197 x 0.036 meters
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.object
body.scale = (0.0985, 0.0985, 0.018)  # Half-size to get full dimensions
body.data.materials.append(mat_aluminum)

# Add bevel modifier to create rounded corners
bevel = body.modifiers.new(name="Bevel", type='BEVEL')
bevel.width = 0.008
bevel.segments = 3

# Join (only one object here, but follow the pattern)
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()

# Name and export
body.name = "SM_MacMini"
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath="/Users/joshua/Documents/Code/vancouvervice/unreal/assets/macmini.fbx", use_selection=True)
print("MACMINI OK")
