; BP_Heat. Manages the wanted level heat system.
; Stars: current heat level (0-5).
; LastSeen: player location when heat was last increased.
; SearchTimer: time spent outside the search circle.
; EventBeginPlay: initialize variables.
; EventTick: count SearchTimer when player is far from LastSeen; drain stars when timer exceeds threshold.
; ShowStars: display stars on screen using PrintString with Key "heat".
;
; Next steps (not in this slice):
; - Spawn pursuit cars from BP_VehicleAdvSportsCar with AI drivers
; - Spawn roadblocks when stars >= 3
; - Add helicopter spotlight when stars == 5
; - Wire AddHeat to collision events and crime actions

(event EventBeginPlay
  (Variables|Default|SetStars 0)
  (Variables|Default|SetSearchTimer 0.0)
  (Variables|Default|SetLastSeen (Math|Vector|MakeVector 0.0 0.0 0.0)))

(event Custom|AddHeat (Amount)
  (bind current (Variables|Default|GetStars))
  (bind new (Math|Clamp (+ current Amount) 0 5))
  (Variables|Default|SetStars new)
  (bind pawn (Game|GetPlayerPawn 0))
  (bind loc (Transformation|GetActorLocation :self pawn))
  (Variables|Default|SetLastSeen loc))

(event EventTick (DeltaSeconds)
  (bind stars (Variables|Default|GetStars))
  (if (> stars 0)
    (bind pawn (Game|GetPlayerPawn 0))
    (bind playerLoc (Transformation|GetActorLocation :self pawn))
    (bind lastLoc (Variables|Default|GetLastSeen))
    (bind dist (Math|Vector|Distance playerLoc lastLoc))
    (if (> dist 3000.0)
      (bind timer (Variables|Default|GetSearchTimer))
      (bind newTimer (+ timer DeltaSeconds))
      (Variables|Default|SetSearchTimer newTimer)
      (bind threshold (* 20.0 stars))
      (if (>= newTimer threshold)
        (Variables|Default|SetStars (- stars 1))
        (Variables|Default|SetSearchTimer 0.0)))
    (else
      (Variables|Default|SetSearchTimer 0.0))))
  (ShowStars))

(event Custom|ShowStars
  (bind stars (Variables|Default|GetStars))
  (bind display "")
  (if (== stars 0) (bind display ""))
  (elif (== stars 1) (bind display "*"))
  (elif (== stars 2) (bind display "**"))
  (elif (== stars 3) (bind display "***"))
  (elif (== stars 4) (bind display "****"))
  (elif (== stars 5) (bind display "*****"))
  (Development|PrintString display :Duration 0.0 :Key "heat"))
