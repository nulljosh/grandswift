"""Grand Swift / Unreal: drop real Vancouver into the open level.

Run inside Unreal Editor 5.8 (Tools > Execute Python Script, or through the Unreal MCP)
with the Cesium for Unreal plugin enabled. Untested until UE is installed.

Reads CESIUM_ION_TOKEN from the environment (it lives in grandswift/.env, never in git).
"""
import os
import unreal

LAT, LON, HEIGHT = 49.2833, -123.1187, 80.0  # Granville & Georgia
GOOGLE_3D_TILES = 2275207                   # Cesium ion asset: Google Photorealistic 3D Tiles

token = os.environ.get("CESIUM_ION_TOKEN", "")
if not token:
    unreal.log_error("Set CESIUM_ION_TOKEN first (see grandswift/.env)")

world = unreal.EditorLevelLibrary.get_editor_world()
spawn = unreal.EditorLevelLibrary.spawn_actor_from_class

# Georeference: puts the level origin on downtown Vancouver
geo = spawn(unreal.CesiumGeoreference, unreal.Vector(0, 0, 0))
geo.set_editor_property("origin_latitude", LAT)
geo.set_editor_property("origin_longitude", LON)
geo.set_editor_property("origin_height", HEIGHT)

# The city itself
tiles = spawn(unreal.Cesium3DTileset, unreal.Vector(0, 0, 0))
tiles.set_editor_property("tileset_source", unreal.TilesetSource.FROM_CESIUM_ION)
tiles.set_editor_property("ion_asset_id", GOOGLE_3D_TILES)
tiles.set_editor_property("ion_access_token", token)
tiles.set_actor_label("Vancouver (Google 3D Tiles)")

# Sun and sky tied to Vancouver's real time of day
sky = spawn(unreal.CesiumSunSky, unreal.Vector(0, 0, 0))
sky.set_actor_label("Vancouver Sun Sky")

# Somewhere to stand
start = spawn(unreal.PlayerStart, unreal.Vector(0, 0, 200))
start.set_actor_label("Start: Granville & Georgia")

unreal.log("Vancouver is in. Next: third person template character, then port stars and missions.")
