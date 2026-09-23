# Run in the editor: python3 unreal/qa.py "$(cat unreal/glasses_install.py)"
# Puts glasses_fit on the player. glasses_fit.fbx is modeled in the face mesh space, so its offset from the
# Mesh "head" socket is the inverse of the face head bone ref pose (both skeletons share that pose).

import unreal
bp=unreal.load_asset("/Game/ThirdPerson/Blueprints/BP_ThirdPersonCharacter")
sds=unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
COMPS={}
for h in sds.k2_gather_subobject_data_for_blueprint(bp):
    o=unreal.SubobjectDataBlueprintFunctionLibrary.get_object(unreal.SubobjectDataBlueprintFunctionLibrary.get_data(h))
    if o: COMPS[o.get_name()]=o
face=COMPS['Face_GEN_VARIABLE'].get_editor_property('skinned_asset')
a=unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.SkeletalMeshActor, unreal.Vector(0,0,100000))
c=a.skeletal_mesh_component; c.set_skinned_asset_and_update(face)
H=c.get_socket_transform('head', unreal.RelativeTransformSpace.RTS_COMPONENT)
a.destroy_actor()
R=H.inverse()
print("rel loc",R.translation.to_tuple(),"rot",R.rotation.rotator().to_tuple())
g=COMPS['Glasses_GEN_VARIABLE']
L="/Game/VancouverVice/Joshua/"
g.set_editor_property('static_mesh', unreal.load_asset(L+"glasses_fit"))
g.set_editor_property('override_materials', [unreal.load_asset(L+"M_Tortoise"), unreal.load_asset(L+"M_Lens"), unreal.load_asset(L+"M_Rivet")])
g.set_editor_property('relative_location', R.translation)
g.set_editor_property('relative_rotation', R.rotation.rotator())
g.set_editor_property('relative_scale3d', unreal.Vector(1,1,1))
unreal.BlueprintEditorLibrary.compile_blueprint(bp)
print(unreal.EditorAssetLibrary.save_loaded_asset(bp, False))
print(g.get_editor_property('static_mesh').get_name(), [m.get_name() for m in g.get_editor_property('override_materials')], g.get_editor_property('relative_location').to_tuple(), g.get_editor_property('relative_rotation').to_tuple())
