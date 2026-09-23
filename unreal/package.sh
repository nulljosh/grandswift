#!/bin/sh
# Packages the vertical slice as a Development Mac .app via RunUAT BuildCookRun.
# Run with the editor CLOSED (see roadmap.md milestone: "Build in the editor without Play; QA
# on the packaged app at each milestone"). Cook/build/pak/archive all want the RAM the editor
# is holding, and BuildCookRun launches its own headless cook anyway.
#
#   sh unreal/package.sh
#
# Output: /Volumes/LaCie/Unreal/Builds/<YYYY-MM-DD>/, with the .app inside Mac/.
# Log: /Volumes/LaCie/Unreal/Builds/<YYYY-MM-DD>/package.log (also unreal/package.log, a symlink
# to the latest run, so `tail -f unreal/package.log` works from a fresh session).

set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ENGINE=/Volumes/LaCie/UE_5.8
RUNUAT="$ENGINE/Engine/Build/BatchFiles/RunUAT.sh"
PROJECT=/Volumes/LaCie/Unreal/VancouverVice/VancouverVice.uproject
DATE=$(date +%Y-%m-%d)
ARCHDIR="/Volumes/LaCie/Unreal/Builds/$DATE"
LOG="$ARCHDIR/package.log"

# --- guards, same idea as doctor.sh's thresholds ---

if pgrep -x UnrealEditor >/dev/null; then
  echo "refusing to package: UnrealEditor is running. Close it first (the cook needs the RAM, and" >&2
  echo "a live editor holding the project can also corrupt the cook)." >&2
  exit 1
fi

free_pct() { memory_pressure 2>/dev/null | awk '/free percentage/ {gsub("%","",$5); print $5}'; }
swap_pct() { sysctl -n vm.swapusage | awk '{gsub("M","",$3); gsub("M","",$6); if ($3>0) printf "%d", $6*100/$3; else print 0}'; }
F=$(free_pct); S=$(swap_pct)
# ponytail: fixed thresholds, same call as doctor.sh's heal(); tune if the Mac gets more RAM.
# A cook is heavier and longer than an editor relaunch, so ask for more headroom (25% vs 15%).
if [ "${F:-0}" -lt 25 ] || [ "${S:-100}" -gt 80 ]; then
  echo "refusing to package: only ${F:-0}% RAM free, swap ${S:-0}% used. Close other apps first." >&2
  exit 1
fi

if [ ! -x "$RUNUAT" ]; then
  echo "RunUAT not found at $RUNUAT (checked the installed 5.8.2 engine on LaCie)" >&2
  exit 1
fi

if [ ! -f "$PROJECT" ]; then
  echo "project not found at $PROJECT" >&2
  exit 1
fi

# TODO before any PUBLIC release: the Cesium ion token baked into the packaged build (Content's
# CesiumIonServer asset / DefaultEngine.ini, sourced from .env's CESIUM_ION_TOKEN today) must be
# swapped for a token restricted to this app the same way CLAUDE.md's rule locks the web token to
# the game's domains (`.env` / `site/config.js`, "The web token is locked to the game's domains").
# An unrestricted dev token in a shipped .app can be pulled out of the binary and abused.
echo "reminder: verify the Cesium ion token is a RESTRICTED token before any public release (see CLAUDE.md)"

mkdir -p "$ARCHDIR"
echo "packaging to $ARCHDIR"
echo "log: $LOG"

# BuildCookRun flags: Development client config for QA (roadmap wants Development, not Shipping,
# for this milestone), Mac platform, build+cook+stage+pak+archive so the archive directory ends
# up with a runnable, self-contained .app. -nop4 skips Perforce (this isn't a P4 depot). -utf8output
# keeps the log readable. -unattended avoids any interactive prompt blocking an unattended run.
# Redirect (not `| tee`) so $? below is RunUAT's real exit status, not sh(1)'s pipefail-less
# pipeline status; tail the log from another terminal to watch it live.
set +e
"$RUNUAT" BuildCookRun \
  -project="$PROJECT" \
  -platform=Mac \
  -clientconfig=Development \
  -build -cook -stage -pak -archive \
  -archivedirectory="$ARCHDIR" \
  -nop4 -utf8output -unattended \
  > "$LOG" 2>&1
STATUS=$?
set -e

ln -sf "$LOG" "$HERE/package.log"

if [ "$STATUS" -ne 0 ]; then
  echo "package FAILED (status $STATUS), see $LOG (or unreal/package.log)" >&2
  tail -40 "$LOG" >&2
  exit "$STATUS"
fi

APP=$(find "$ARCHDIR" -maxdepth 4 -name "*.app" -print -quit)
if [ -n "$APP" ]; then
  echo "packaged: $APP"
else
  echo "BuildCookRun reported success but no .app was found under $ARCHDIR, check $LOG" >&2
  exit 1
fi
