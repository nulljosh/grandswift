; BP_ThirdPersonCharacter UserConstructionScript. Mesh (the hidden mannequin) animates; Body, Face and Polo copy its pose.
; Glasses ride the Mesh head socket.
(fn ConstructionScript ()
  (Components|SkinnedMesh|SetLeaderPoseComponent (Variables|Default|GetBody) (Variables|Character|GetMesh))
  (Components|SkinnedMesh|SetLeaderPoseComponent (Variables|Default|GetFace) (Variables|Character|GetMesh))
  (Components|SkinnedMesh|SetLeaderPoseComponent (Variables|Default|GetPolo) (Variables|Character|GetMesh))
  (Transformation|AttachComponentToComponent (Variables|Default|GetGlasses) (Variables|Character|GetMesh) "head"))
