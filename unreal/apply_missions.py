# Run in the editor through the bridge: python3 qa.py "$(cat apply_missions.py)"
bp = unreal.load_asset("/Game/VancouverVice/BP_Missions")
cdo = unreal.get_default_object(bp.generated_class())
cdo.set_editor_property("Targets", [unreal.Vector(814, 1614, 0), unreal.Vector(-14005, 5010, 0), unreal.Vector(-63876, 80134, 0), unreal.Vector(51118, -26606, 0)])
cdo.set_editor_property("MissionNames", ["Rob the Apple Store: grab the Mac minis and run", "Lose the heat: run to the Art Gallery steps", "Rob the 7-Eleven on Granville", "Get to Waterfront Station before the cops"])
bp.modify(); unreal.EditorAssetLibrary.save_loaded_asset(bp)
print("missions", cdo.get_editor_property("MissionNames"))
