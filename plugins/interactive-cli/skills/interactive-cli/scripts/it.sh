#!/usr/bin/env bash
# it.sh — drive interactive CLI programs via tmux so Claude can read prompts
# and send input itself (no human needed at the keyboard).
#
# Usage:
#   it.sh start <name> <command...>   # launch <command> in a detached tmux session
#   it.sh read  <name> [lines]        # capture last [lines] (default 60) of the pane
#   it.sh send  <name> <text...>      # type <text> then press Enter
#   it.sh type  <name> <text...>      # type <text> WITHOUT Enter
#   it.sh key   <name> <keys...>      # send raw tmux key(s): Enter, C-c, Up, Down, Space, Tab...
#   it.sh wait  <name> <regex> [secs] # poll pane until <regex> appears (default 30s); exit 0 hit / 1 timeout
#   it.sh alive <name>                # exit 0 if session/command still running, else 1
#   it.sh kill  <name>                # kill the session
#   it.sh list                        # list live sessions
#
# Typical loop: start -> wait (for a prompt) -> read -> send -> wait -> ... -> kill
set -euo pipefail

SOCK="claude-it"                          # dedicated tmux server, isolated from user's tmux
TM() { tmux -L "$SOCK" "$@"; }

cmd="${1:-}"; shift || true

case "$cmd" in
  start)
    name="$1"; shift
    TM kill-session -t "$name" 2>/dev/null || true
    TM new-session -d -s "$name" -x 220 -y 50 "$*"
    # keep the pane (and its final output) readable after the command exits
    TM set-option -t "$name" remain-on-exit on 2>/dev/null || true
    echo "started '$name': $*"
    ;;
  read)
    name="$1"; lines="${2:-60}"
    TM capture-pane -p -t "$name" -S "-${lines}"
    ;;
  send)
    name="$1"; shift
    TM send-keys -t "$name" -- "$*"
    TM send-keys -t "$name" Enter
    ;;
  type)
    name="$1"; shift
    TM send-keys -t "$name" -- "$*"
    ;;
  key)
    name="$1"; shift
    TM send-keys -t "$name" "$@"
    ;;
  wait)
    name="$1"; re="$2"; secs="${3:-30}"
    for ((i=0; i<secs*2; i++)); do
      if TM capture-pane -p -t "$name" -S -200 2>/dev/null | grep -Eq -- "$re"; then
        echo "matched: $re"; exit 0
      fi
      # if the program already exited, stop waiting
      TM has-session -t "$name" 2>/dev/null || { echo "session ended before match"; exit 1; }
      sleep 0.5
    done
    echo "timeout after ${secs}s waiting for: $re"; exit 1
    ;;
  alive)
    name="$1"
    TM has-session -t "$name" 2>/dev/null || { echo "no session"; exit 1; }
    dead=$(TM display-message -p -t "$name" '#{pane_dead}' 2>/dev/null || echo 1)
    [ "$dead" = "0" ] && echo "running" || { echo "exited"; exit 1; }
    ;;
  kill)
    name="$1"
    TM kill-session -t "$name" 2>/dev/null && echo "killed '$name'" || echo "no session '$name'"
    ;;
  list)
    TM list-sessions 2>/dev/null || echo "(no sessions)"
    ;;
  *)
    echo "usage: it.sh {start|read|send|type|key|wait|alive|kill|list} ..." >&2
    exit 2
    ;;
esac
