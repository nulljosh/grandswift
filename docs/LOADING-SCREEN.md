# Loading screen

`docs/loading-screen-mockup.html` is a static visual reference for the ~90s wait while
Cesium streams Google's 3D tiles in. Not wired into Unreal — open it in a browser to see
the target look; the team builds the real widget from it.

## Maps to a UMG Widget Blueprint

- **Full-screen Image or Canvas Panel** as the root, dark fill + the rain/skyline layers
  baked as a texture or a simple particle/material overlay.
- **TextBlock (title)** — "Vancouver Vice", static.
- **TextBlock (tip)** — text swapped on a timer, fade in/out via a WidgetAnimation.
- **ProgressBar** — `Percent` bound to `Cesium3DTileset::GetLoadProgress`, same call
  `unreal/missions.dsl`'s `EventTick` already uses (line 9: `Class|Cesium3DTileset|GetLoadProgress`)
  to sharpen `MaximumScreenSpaceError` once tiles pass 60%. Reuse that binding instead of
  re-deriving progress.
- **Widget removal** — hide/remove the loading widget from the same tick once
  `GetLoadProgress` crosses the sharpen threshold (or a "fully streamed" check), mirroring
  the `Variables|Default|SetSharpened` guard already in `EventTick`.

## Tip rotation timer

Lives alongside the existing `EventTick` in `BP_Missions` (see `unreal/missions.dsl` lines
7-22 for the pattern: a bound tileset ref, a state flag read each tick, and a guarded
one-shot action). Add a `TipTimer` float accumulated in `EventTick`, and when it crosses
~4.2s, advance a `TipIndex` into the tip array and reset the timer — same shape as the
`idx`/`targets` walk already there, just swapped to widget text instead of mission targets.
