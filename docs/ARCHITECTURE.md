# How Vancouver Vice works

Three versions of one game, sharing the same rules and map data.

## The pieces
| Part | Where | What it does |
|---|---|---|
| Main game | `site/play.html` | Simplified Vancouver and Victoria with all the gameplay: missions, cops, heroes, weapons, weather, saves. three.js, runs anywhere. |
| Real streets | `site/city.html` | Downtown, Kits, Victoria and Langley built from OpenStreetMap. Real buildings, signs, shops you walk into, traffic, cops, SkyTrain, online play. |
| Real Vancouver beta | `site/real.html` | Google photorealistic 3D tiles streamed through Cesium. |
| Unreal version | `unreal/`, `UNREAL.md` | The high-end build, set up through Unreal's MCP. In progress. |
| Online world | `worker.js` | One Cloudflare Durable Object relays player positions. |
| Map exporter | `tools/osm.py` | Pulls buildings, roads, parks, water, shops, SkyTrain lines and stations from OpenStreetMap. |
| Apps | `apps/` | Native shells: Windows C#, Linux C, Mac and iOS SwiftUI, Android Java. Each opens the live game. |
| Models | `site/models/` | Hero and 12 people (Rocketbox, MIT), converted with Blender. |

## How the city is built
`tools/osm.py` turns OpenStreetMap into local metres around a centre point. `city.html` extrudes every building footprint to its real height, lays roads as ribbons, and indexes footprints in a 25 metre grid so collision is one point-in-polygon test. Places from OpenStreetMap map to the building they sit in, which is how walking into a building knows it's a 7-Eleven.

## How the game stays smooth
Buildings are merged into a handful of meshes. Traffic, lamps and trees are instanced. People are only animated near you. Post effects are desktop only.

## Shipping
`npx wrangler deploy` publishes `site/` and the online worker. Tagging `v*` makes GitHub Actions build every app and attach it to a release. Apps are signed when signing secrets exist, unsigned otherwise.
