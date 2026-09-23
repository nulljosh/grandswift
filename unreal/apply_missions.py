# Run in the editor through the bridge: python3 qa.py "$(cat apply_missions.py)"
bp = unreal.load_asset("/Game/VancouverVice/BP_Missions")
cdo = unreal.get_default_object(bp.generated_class())
cdo.set_editor_property("Targets", [unreal.Vector(814, 4800, 0), unreal.Vector(-14005, 5010, 0), unreal.Vector(-63876, 80134, 0), unreal.Vector(51118, -26606, 0)])
cdo.set_editor_property("MissionNames", ["Get out of here: run from the Apple Store with the Mac minis", "Jack a car and lose the cops past the Art Gallery", "Pawn the Mac minis on Granville", "Lie low at Waterfront Station"])
bp.modify(); unreal.EditorAssetLibrary.save_loaded_asset(bp)
print("missions", cdo.get_editor_property("MissionNames"))
