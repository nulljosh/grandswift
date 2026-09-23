; Draft only, not yet applied via apply_missions.py. In-game self-test for the packaged .app:
; launch with -autoplay, it walks the player toward mission one's target (same idea as
; unreal/qa_walk.py's Python driver, but running inside the packaged game instead of the editor),
; writes PASS/FAIL plus a timestamp to Saved/Autoplay/result.txt, takes a HighResShot, then quits.
;
; Put on BP_ThirdPersonCharacter (has Tick already, and is the actor whose movement we're driving)
; or a small new BP_Autoplay actor placed in the level; either works, comments below assume the
; character. Node names below follow the "Category|Subcategory|Function" style used across the
; other .dsl files in this folder (missions.dsl, heat.dsl, fasttravel.dsl, controller.dsl), which
; all read as the Blueprint node's real category/display name. The four marked UNCERTAIN below have
; no precedent anywhere in this repo's existing .dsl files, so the exact category path is a
; best guess from the underlying UFUNCTION (UKismetSystemLibrary etc) and should be checked
; against the real node picker in the editor before this gets applied.

; UNCERTAIN: the real node is UKismetSystemLibrary::ParseParam (BlueprintPure, "does the command
; line contain -Param"). Editor search text is usually "Parse Param"; category shown in different
; UE versions has been plain "Utilities" as well as "Utilities|String" like Append here. Confirm
; in the node picker; if wrong, GetCommandLine + a String|Contains check is the fallback.
(event EventBeginPlay
  (bind cmdline (Utilities|GetCommandLine))
  (bind autoplay (Utilities|String|ParseParam :InString cmdline :InParam "autoplay"))
  (if autoplay
    (Variables|Default|SetAutoplayActive true)
    (Variables|Default|SetAutoplayStart (Utilities|Time|GetGameTimeInSeconds))
    (Variables|Default|SetAutoplayStartLoc (Transformation|GetActorLocation :self self))))

; Tick only does anything once EventBeginPlay above set AutoplayActive. Mirrors qa_walk.py:
; steer at the mission-one target every frame, add movement input, stop on arrival or 60 s timeout.
(event EventTick (DeltaSeconds)
  (if (Variables|Default|GetAutoplayActive)
    (bind missions (Actor|GetActorOfClass :ActorClass "/Game/VancouverVice/BP_Missions.BP_Missions_C"))
    (bind idx (Class|BP_Missions|GetIndex :self missions))
    (bind elapsed (- (Utilities|Time|GetGameTimeInSeconds) (Variables|Default|GetAutoplayStart)))
    (if (or (>= idx 1) (> elapsed 60.0))
      (bind passed (>= idx 1))
      (Custom|AutoplayFinish passed elapsed)
      (else
        (bind targets (Class|BP_Missions|GetTargets :self missions))
        (bind target (Utilities|Array|Get(acopy) targets 0))
        (bind loc (Transformation|GetActorLocation :self self))
        (bind delta (Math|Vector|Subtract target loc))
        (bind dir (Math|Vector|Normal2D delta))
        (Pawn|AddMovementInput :self self :WorldDirection dir :ScaleValue 1.0)))))

; Writes the result file, screenshots, and quits. Runs once (AutoplayActive guards re-entry).
(event Custom|AutoplayFinish (Passed Elapsed)
  (Variables|Default|SetAutoplayActive false)
  (bind stamp (Utilities|Time|Now))
  (bind status (select Passed "PASS" "FAIL"))
  (bind line (Utilities|String|Append status (Utilities|String|Append " " (Utilities|String|Append (Utilities|Text|ToString stamp) (Utilities|String|Append " elapsed=" (Utilities|Conversions|FloatToString Elapsed))))))
  ; UNCERTAIN: no plain "write text file" node exists in a packaged game without a plugin.
  ; UKismetSystemLibrary has no Blueprint-exposed SaveStringToFile at runtime; the Editor
  ; Scripting Utilities plugin's "Save String To Text File" is editor-only and would not run in
  ; the packaged .app. Two real options, pick one when this gets applied:
  ;   (a) enable the small "Text IO" style plugin or add one BlueprintCallable C++ helper that
  ;       wraps FFileHelper::SaveStringToFile(String, *(FPaths::ProjectSavedDir() / "Autoplay" / "result.txt"))
  ;   (b) if only a plugin-provided node is available, its category will differ from the guess below.
  ; Node path assumed here mirrors the "Utilities|File|..." shape the DSL uses elsewhere for
  ; casting/utility calls; confirm the actual name in the node picker before applying.
  (Utilities|File|SaveStringToFile :self self :SaveDirectory (Utilities|Paths|ProjectSavedDir) :FileName "Autoplay/result.txt" :SaveText line)
  ; UNCERTAIN: HighResShot is normally driven as a console command ("HighResShot 1920x1080"),
  ; which doctor.sh's heal() already does from Python via execute_console_command. The Blueprint
  ; equivalent is ExecuteConsoleCommand (UKismetSystemLibrary, category commonly just "Utilities"
  ; or "Development|Editor" depending on UE version); confirm before applying.
  (Development|Debug|ExecuteConsoleCommand :self self :Command "HighResShot 1920x1080" :SpecificPlayer (Game|GetPlayerController 0))
  (Utilities|FlowControl|Delay :Duration 1.0)  ; let the screenshot finish writing before quitting
  ; QuitGame is a real, well-known UKismetSystemLibrary node (category "Game"), matching the
  ; Game|GetPlayerPawn style already used in missions.dsl and qa_walk.py.
  (Game|QuitGame :SpecificPlayerController (Game|GetPlayerController 0) :QuitPreference "Quit" :bIgnorePlatformRestrictions false))
