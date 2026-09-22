"""Scan a real person into Vancouver Vice.
Usage: python3 face_scan.py <LiveLinkFace.zip> <Name> [neutral_frame=60]
Needs the editor open with the QA bridge. Frame 60 = 1 s in at 60 fps; pick a frame where they look straight at the phone, neutral face.
Steps: unzip -> ingest (ffmpeg) -> MetaHuman Identity (track + conform) -> new MetaHuman Character /Game/VancouverVice/Faces/<Name> shaped like them.
Rig, skin textures and build are the cloud step, run in the Creator after this (needs Epic login).
"""
import os, sys, time, zipfile, subprocess
from qa import run

zip_path, name = sys.argv[1], sys.argv[2]
frame = int(sys.argv[3]) if len(sys.argv) > 3 else 60
dest = f"/Volumes/LaCie/Unreal/Captures/{name}"
zipfile.ZipFile(zip_path).extractall(dest)
take = next(r for r, _, f in os.walk(dest) if "take.json" in f)
mov = next(os.path.join(take, f) for f in os.listdir(take) if f.endswith(".mov"))
subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(frame / 60), "-i", mov, "-frames:v", "1", "-vf", "scale=360:-1", f"/tmp/{name}_neutral.jpg"])
print("neutral frame preview:", f"/tmp/{name}_neutral.jpg")

flag = f"/tmp/vv_qa/ingest_{name}.txt"
if os.path.exists(flag): os.remove(flag)
print(run(f'''
s=unreal.get_default_object(unreal.CaptureManagerEditorSettings)
fp=unreal.FilePath(); fp.set_editor_property("file_path","/opt/homebrew/bin/ffmpeg")
s.set_editor_property("third_party_encoder",fp); s.set_editor_property("enable_third_party_encoder",True)
ok=unreal.CaptureManagerIngestSuccess(); bad=unreal.CaptureManagerIngestFailed()
def _ok(a,b,c): open("{flag}","w").write("OK "+c.get_path_name().split(".")[0])
def _bad(a,b,c): open("{flag}","w").write("FAIL "+str(c))
ok.bind_callable(_ok); bad.bind_callable(_bad); globals()["_keep_{name}"]=(ok,bad,_ok,_bad)
print("ingest id", unreal.CaptureManagerIngestBlueprintLibrary.ingest_live_link_face("{take}", unreal.CaptureManagerConversionParams(), ok, bad))'''))
end = time.time() + 1800  # ponytail: 30 min cap, a 1 min take ingests in about 2
while not os.path.exists(flag) and time.time() < end: time.sleep(10)
res = open(flag).read() if os.path.exists(flag) else "FAIL timeout"
print(res)
if not res.startswith("OK"): sys.exit(1)
cd = res.split(" ", 1)[1]

print(run(f'''
import create_identity_for_performance as c
from metahuman_character_test_utils import ScopedMetaHumanCharacterEditor
folder="/Game/VancouverVice/Faces"
c.create_identity_from_frame({frame}, "{cd}", folder, "MHI_{name}", False, 3)
ident=unreal.load_asset(folder+"/MHI_{name}")
mh=unreal.load_asset(folder+"/{name}") or unreal.AssetToolsHelpers.get_asset_tools().create_asset("{name}", folder, unreal.MetaHumanCharacter, unreal.new_object(type=unreal.MetaHumanCharacterFactoryNew))
sub=unreal.get_editor_subsystem(unreal.MetaHumanCharacterEditorSubsystem)
with ScopedMetaHumanCharacterEditor(character=mh):
    p=unreal.ImportFromIdentityParams(); p.use_eye_meshes=True; p.use_teeth_mesh=True
    print("conform", sub.import_from_identity(mh, ident, p))
unreal.EditorAssetLibrary.save_loaded_asset(ident); unreal.EditorAssetLibrary.save_loaded_asset(mh)
print("character", mh.get_path_name())''', timeout=900))
