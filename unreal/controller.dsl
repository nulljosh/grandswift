; BP_ThirdPersonPlayerController. BeginPlay: walking controls. E: jump in the nearest getaway car, E again to get out.
(event EventBeginPlay
  (Utilities|FlowControl|DelayUntilNextTick)
  (if (Pawn|IsLocalPlayerController)
    (Input|AddMappingContext (LocalPlayerSubsystems|GetEnhancedInputLocalPlayerSubsystem) "/Game/Input/IMC_Default.IMC_Default" 0 "(bIgnoreAllPressedKeysUntilRelease=True,bForceImmediately=False,bNotifyUserSettings=False)")
    (if (Default|ShouldUseTouchControls)
      (bind _returnvalue (UserInterface|CreateWidget (Variables|Input|TouchControls|GetTouchControlsWidgetClass) self))
      (UserInterface|Viewport|AddToPlayerScreen _returnvalue)
      (else
        (Input|AddMappingContext (LocalPlayerSubsystems|GetEnhancedInputLocalPlayerSubsystem) "/Game/Input/IMC_MouseLook.IMC_MouseLook" 0 "(bIgnoreAllPressedKeysUntilRelease=True,bForceImmediately=False,bNotifyUserSettings=False)")))))

(event Custom|EnterOrExitCar
  (bind car (Actor|GetActorOfClass :ActorClass "/Game/VehicleTemplate/Blueprints/SportsCar/BP_VehicleAdvSportsCar.BP_VehicleAdvSportsCar_C"))
  (bind walker (Actor|GetActorOfClass :ActorClass "/Game/ThirdPerson/Blueprints/BP_ThirdPersonCharacter.BP_ThirdPersonCharacter_C"))
  (if (== (Pawn|GetControlledPawn) car)
    (Transformation|DetachFromActor walker)
    (Transformation|SetActorLocation walker (+ (Transformation|GetActorLocation car) (Math|Vector|MakeVector 0.0 0.0 250.0)))
    (Rendering|SetActorHiddenInGame walker false)
    (Collision|SetActorEnableCollision walker true)
    (Input|RemoveMappingContext (LocalPlayerSubsystems|GetEnhancedInputLocalPlayerSubsystem) "/Game/VehicleTemplate/Input/IMC_Vehicle_Default.IMC_Vehicle_Default")
    (Pawn|Possess :InPawn walker)
    (elif (< (Transformation|GetDistanceTo walker car) 600.0)
      (Rendering|SetActorHiddenInGame walker true)
      (Collision|SetActorEnableCollision walker false)
      (Transformation|AttachActorToActor walker car)
      (Input|AddMappingContext (LocalPlayerSubsystems|GetEnhancedInputLocalPlayerSubsystem) "/Game/VehicleTemplate/Input/IMC_Vehicle_Default.IMC_Vehicle_Default" 1 "(bIgnoreAllPressedKeysUntilRelease=True,bForceImmediately=False,bNotifyUserSettings=False)")
      (Pawn|Possess :InPawn car))))
