; Custom event on BP_ThirdPersonPlayerController, wired to IA_FastTravel (Tab) the same way IA_EnterCar is wired.
; Each press moves the world origin to the next city. Google streams whatever city the origin sits on, so the
; player stays at the same spot on screen and the new city loads in under them. Coordinates: street corners.
(event Custom|FastTravel
  (bind geo (Utilities|Casting|CastToCesiumGeoreference :Object (Actor|GetActorOfClass :ActorClass "/Script/CesiumRuntime.CesiumGeoreference")))
  (bind idx (% (+ (Variables|Default|GetCityIndex) 1) 5))
  (Variables|Default|SetCityIndex idx)
  (switch int idx
    (:0 (Class|CesiumGeoreference|SetOriginLongitudeLatitudeHeight :self geo :TargetLongitudeLatitudeHeight (Math|Vector|MakeVector -123.1187 49.2833 80.0))
        (Development|PrintString "Vancouver: Granville and Georgia" :Duration 4.0))
    (:1 (Class|CesiumGeoreference|SetOriginLongitudeLatitudeHeight :self geo :TargetLongitudeLatitudeHeight (Math|Vector|MakeVector -123.3693 48.4235 80.0))
        (Development|PrintString "Victoria: Government Street" :Duration 4.0))
    (:2 (Class|CesiumGeoreference|SetOriginLongitudeLatitudeHeight :self geo :TargetLongitudeLatitudeHeight (Math|Vector|MakeVector -122.3355 47.6090 80.0))
        (Development|PrintString "Seattle: Pike Place" :Duration 4.0))
    (:3 (Class|CesiumGeoreference|SetOriginLongitudeLatitudeHeight :self geo :TargetLongitudeLatitudeHeight (Math|Vector|MakeVector -79.3832 43.6532 80.0))
        (Development|PrintString "Toronto: Yonge and Queen" :Duration 4.0))
    (:4 (Class|CesiumGeoreference|SetOriginLongitudeLatitudeHeight :self geo :TargetLongitudeLatitudeHeight (Math|Vector|MakeVector -73.9855 40.7580 80.0))
        (Development|PrintString "New York: Times Square" :Duration 4.0))))
