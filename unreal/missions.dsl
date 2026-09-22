; BP_Missions. BeginPlay: city starts medium so the streets under the player appear fast.
; Tick: sharpen to max once the first load finishes, then run the mission list.
(event EventBeginPlay
  (bind tiles (Utilities|Casting|CastToCesium3DTileset :Object (Actor|GetActorOfClass :ActorClass "/Script/CesiumRuntime.Cesium3DTileset")))
  (Class|Cesium3DTileset|SetMaximumScreenSpaceError :self tiles :MaximumScreenSpaceError 8.0))

(event EventTick (DeltaSeconds)
  (bind tiles (Utilities|Casting|CastToCesium3DTileset :Object (Actor|GetActorOfClass :ActorClass "/Script/CesiumRuntime.Cesium3DTileset")))
  (if (and (not (Variables|Default|GetSharpened)) (>= (Class|Cesium3DTileset|GetLoadProgress :self tiles) 60.0))
    (Class|Cesium3DTileset|SetMaximumScreenSpaceError :self tiles :MaximumScreenSpaceError 4.0)
    (Variables|Default|SetSharpened true))
  (bind targets (Variables|Default|GetTargets))
  (bind names (Variables|Default|GetMissionNames))
  (bind idx (Variables|Default|GetIndex))
  (if (< idx (Utilities|Array|Length targets))
    (bind target (Utilities|Array|Get(acopy) targets idx))
    (bind name (Utilities|Array|Get(acopy) names idx))
    (bind pawn (Game|GetPlayerPawn 0))
    (bind loc (Transformation|GetActorLocation :self pawn))
    (Rendering|Debug|DrawDebugSphere :Center (Math|Vector|MakeVector :X (.x target) :Y (.y target) :Z (.z loc)) :Radius 250.0 :Segments 12 :Duration 0.0 :Thickness 8.0)
    (Development|PrintString (Utilities|String|Append "Mission: " name) :Duration 0.0 :Key "mission")
    (if (< (Math|Vector|Distance2D(Vector) loc target) 400.0)
      (Development|PrintString (Utilities|String|Append "Mission complete: " name) :Duration 4.0)
      (Variables|Default|SetIndex (+ idx 1)))
    (else
      (Development|PrintString "All missions done. Vancouver is yours." :Duration 0.0 :Key "mission"))))
