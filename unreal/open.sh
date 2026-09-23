#!/bin/sh
# Opens the Vancouver Vice Unreal project with the MCP server already running on port 18000 (8000 is taken by the local LLM server).
# idle local LLMs hold 5 GB; unload them before Unreal boots
command -v ollama >/dev/null && ollama ps 2>/dev/null | awk 'NR>1 {print $1}' | xargs -n1 ollama stop 2>/dev/null
open -a /Volumes/LaCie/UE_5.8/Engine/Binaries/Mac/UnrealEditor.app --args /Volumes/LaCie/Unreal/VancouverVice/VancouverVice.uproject -ExecCmds="ModelContextProtocol.StartServer 18000,stat none,trace.stop" -notrace
