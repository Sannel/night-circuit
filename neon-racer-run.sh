#!/bin/bash
# Night Circuit 2076 screensaver runner.
# Serves the cinematic HTML in a chromium app window scaled to the focused
# monitor, and tears everything down when the page's /exit is hit (user
# input) or the window disappears.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$DIR/night-circuit.html"
PIDFILE="$XDG_RUNTIME_DIR/night-circuit.pid"
LOG="${XDG_RUNTIME_DIR:-/tmp}/night-circuit.log"

# ---- single instance: pidfile + flock, immune to self/ancestor matching ----
LFILE="$XDG_RUNTIME_DIR/night-circuit.lock"
exec 9>"$LFILE"
flock -n 9 || exit 1
if [[ -s $PIDFILE ]] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
  exit 1
fi
echo $$ > "$PIDFILE"

# ---- honor the screensaver-off toggle unless forced ---------------------
if omarchy-toggle-enabled screensaver-off 2>/dev/null && [[ $1 != "force" ]]; then
  exit 1
fi

[[ -r "$HTML" ]] || { echo "missing $HTML" >&2; exit 1; }
command -v chromium >/dev/null || { echo "chromium not found" >&2; exit 1; }

PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')

exec >"$LOG" 2>&1
echo "pid=$$ start=$(date +%T)"

# ---- launch local server ------------------------------------------------
python3 "$DIR/server.py" "$DIR" "$PORT" &
SERVER_PID=$!

# parse reported port if server picked a different one (shouldn't happen)
sleep 0.4

cleanup() {
  if [[ -n $CHROME_PID ]]; then
    kill -TERM -- "-$CHROME_PID" 2>/dev/null
    sleep 1
    kill -KILL -- "-$CHROME_PID" 2>/dev/null
  fi
  kill "$SERVER_PID" 2>/dev/null
  rm -f "$PIDFILE"
  echo "exit=$(date +%T)"
  exit 0
}
trap cleanup EXIT INT TERM

# ---- resolve focused monitor geometry ------------------------------------
read MONX MONY MONW MONH < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height)"' | head -1)
MONX=${MONX:-0}; MONY=${MONY:-0}; MONW=${MONW:-1920}; MONH=${MONH:-1080}

# ---- open chromium app window -------------------------------------------
URL_TAG="?v=$RANDOM$RANDOM"
setsid chromium \
  --app="http://127.0.0.1:$PORT/$URL_TAG" \
  --window-size="$MONW,$MONH" --window-position=0,0 \
  --no-first-run --no-default-browser-check --disable-session-crashed-bubble \
  --hide-crash-restore-bubble --disable-infobars --noerrdialogs \
  --password-store=basic --disable-component-update --no-pings \
  --disable-features=Translate,MediaRouter >/dev/null 2>&1 &
CHROME_PID=$!

# ---- wait for the window to map ------------------------------------------
OURS=""
deadline=$((SECONDS + 10))
while ((SECONDS < deadline)); do
  OURS=$(hyprctl clients -j 2>/dev/null | jq -r --argjson pid "$CHROME_PID" '.[] | select(.pid == $pid) | .address' | head -1)
  [[ -n $OURS ]] && break
  kill -0 "$CHROME_PID" 2>/dev/null || cleanup
  sleep 0.2
done
[[ -n $OURS ]] || cleanup
echo "window=$OURS"
# ---- keep running until: page input kills the server, or our window dies --
while kill -0 "$CHROME_PID" 2>/dev/null && kill -0 "$SERVER_PID" 2>/dev/null; do
  sleep 2
  GONE=$(hyprctl clients -j 2>/dev/null | jq --arg a "$OURS" '[.[] | select(.address == $a)] | length')
  [[ $GONE == "0" ]] && break
done
cleanup