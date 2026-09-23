#!/bin/sh
# Keeps the Unreal side healthy without anyone at the Mac.
#   sh unreal/doctor.sh          status: editor, control port, RAM, crash leftovers, recent errors
#   sh unreal/doctor.sh lean     free RAM for Unreal: unload local LLMs, drop GPU caches in the editor
#   sh unreal/doctor.sh heal     clear crash leftovers, relaunch the editor if it died (only if RAM allows), wait for the port
HERE=$(cd "$(dirname "$0")" && pwd)
LOG="$HOME/Library/Logs/Unreal Engine/VancouverViceEditor/VancouverVice.log"
editor() { pgrep -x UnrealEditor | head -1; }
port() { curl -s -o /dev/null -m 2 http://127.0.0.1:18000/mcp && echo up || echo down; }
swap_pct() { sysctl -n vm.swapusage | awk '{gsub("M","",$3); gsub("M","",$6); if ($3>0) printf "%d", $6*100/$3; else print 0}'; }
# ponytail: editor footprint in GB (RAM + compressed + swap); 20 GB is where a 16 GB Mac starts thrashing
foot_gb() { e=$(editor); [ -n "$e" ] && footprint "$e" 2>/dev/null | awk '/Footprint:/ {for(i=1;i<NF;i++) if($i=="Footprint:"){v=$(i+1); if($(i+2)=="MB") v=v/1024; if($(i+2)=="KB") v=0; printf "%d", v}}'; }
free_pct() { memory_pressure 2>/dev/null | awk '/free percentage/ {gsub("%","",$5); print $5}'; }

status() {
  e=$(editor)
  if [ -n "$e" ]; then echo "editor:   running pid $e, up $(ps -o etime= -p $e | tr -d ' ')"; else echo "editor:   not running"; fi
  echo "port:     $(port)"
  echo "memory:   $(free_pct)% free, swap $(swap_pct)% used"
  g=$(foot_gb); [ -n "$g" ] && echo "footprint: ${g} GB$([ "$g" -gt 20 ] && echo '  RESTART DUE: save all, quit, open.sh')"
  echo "leftover: $(pgrep -f CrashReportClient >/dev/null && echo 'crash dialog open' || echo none)"
  echo "launcher: $(pgrep -x EpicGamesLauncher-Mac-Shipping >/dev/null && echo running || echo closed)"
  echo "errors since launch:"
  grep -E 'Assertion failed|Critical error|Fatal|Error:' "$LOG" 2>/dev/null | grep -v -E 'TryAddObjectToEdit|idevice' | tail -3 | cut -c1-160
}

heal() {
  # crash leftovers: the report window and helpers orphaned by a dead editor
  pkill -9 -f CrashReportClient 2>/dev/null
  [ -z "$(editor)" ] && pkill -f UnrealTraceServer 2>/dev/null
  if [ -z "$(editor)" ]; then
    f=$(free_pct); s=$(swap_pct)
    # ponytail: fixed thresholds; tune if the Mac gets more RAM
    if [ "${f:-0}" -lt 15 ] || [ "${s:-100}" -gt 90 ]; then
      echo "not relaunching: only ${f}% RAM free, swap ${s}% used. Close something first."; exit 2
    fi
    echo "editor was down, relaunching"; sh "$HERE/open.sh"
  fi
  # editor alive but port dead: a crashed editor held 18000 when this one started, and it never retries.
  # The file bridge (qa.py) does not need the port, so use it to restart the MCP server.
  if [ -n "$(editor)" ] && [ "$(port)" = down ] && grep -q 'unable to bind to 127.0.0.1:18000' "$LOG" 2>/dev/null; then
    python3 "$HERE/qa.py" 'import unreal
unreal.SystemLibrary.execute_console_command(None, "ModelContextProtocol.StartServer 18000")' >/dev/null 2>&1 && echo "restarted the MCP server on 18000"
  fi
  i=0; while [ "$(port)" = down ] && [ $i -lt 90 ]; do sleep 10; i=$((i+1)); done
  [ "$(port)" = up ] && echo "healthy: editor up, port 18000 answering" || { echo "editor did not come up in 15 min"; exit 1; }
}

lean() {
  # the local LLMs are the other big RAM users on this Mac
  command -v ollama >/dev/null && ollama ps 2>/dev/null | awk 'NR>1 {print $1}' | xargs -n1 ollama stop 2>/dev/null
  pkill -f omlx 2>/dev/null && echo "stopped omlx"
  [ -n "$(editor)" ] && python3 "$HERE/qa.py" 'import unreal
for c in ["stat none","r.Streaming.PoolSize 1000","t.MaxFPS 30","r.ScreenPercentage 60","FlushUnusedMemory"]: unreal.SystemLibrary.execute_console_command(None, c)' >/dev/null 2>&1 && echo "editor trimmed"
}

case "$1" in lean) lean; status ;; heal) heal; status ;; *) status ;; esac
