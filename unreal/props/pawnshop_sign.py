import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)

# Create materials
mat_sign = bpy.data.materials.new("SignFace")
mat_sign.diffuse_color = (0.2, 0.15, 0.05, 1.0)  # Dark green/gold base

mat_bracket = bpy.data.materials.new("Bracket")
mat_bracket.diffuse_color = (0.3, 0.25, 0.15, 1.0)  # Darker bracket

objs = []

# Main sign face: 1.2m x 0.5m x 0.05m
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
sign = bpy.context.object
sign.scale = (0.6, 0.25, 0.025)
sign.data.materials.append(mat_sign)
objs.append(sign)

# Bracket detail: thin cylinder at top, holding the sign
# Position at top of sign (z = 0.275)
bpy.ops.mesh.primitive_cylinder_add(radius=0.015, depth=0.04, location=(0, 0, 0.285))
bracket = bpy.context.object
bracket.rotation_euler = (1.5708, 0, 0)  # Rotate 90 degrees to align
bracket.scale = (1.0, 0.8, 1.0)
bracket.data.materials.append(mat_bracket)
objs.append(bracket)

# Chain links (small cylinders) descending from bracket
for i in range(3):
    z_pos = 0.27 - (i * 0.08)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.025, location=(-0.35, 0, z_pos))
    link = bpy.context.object
    link.rotation_euler = (1.5708, 0, 0)
    link.data.materials.append(mat_bracket)
    objs.append(link)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.025, location=(0.35, 0, z_pos))
    link2 = bpy.context.object
    link2.rotation_euler = (1.5708, 0, 0)
    link2.data.materials.append(mat_bracket)
    objs.append(link2)

# Join all objects
bpy.ops.object.select_all(action='DESELECT')
for o in objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
bpy.ops.object.join()

obj = bpy.context.object
obj.name = "SM_PawnShopSign"
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath="/Users/joshua/Documents/Code/vancouvervice/unreal/assets/pawnshop_sign.fbx", use_selection=True)
print("PAWNSHOPSIGN OK")
