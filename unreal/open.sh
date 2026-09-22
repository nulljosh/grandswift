#!/bin/sh
# Opens the Vancouver Vice Unreal project with the MCP server already running on port 18000 (8000 is taken by the local LLM server).
open -a /Volumes/LaCie/UE_5.8/Engine/Binaries/Mac/UnrealEditor.app --args /Volumes/LaCie/Unreal/VancouverVice/VancouverVice.uproject -ExecCmds="ModelContextProtocol.StartServer 18000"
