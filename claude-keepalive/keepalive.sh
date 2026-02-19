#!/usr/bin/env zsh
# =============================================================================
# claude-keepalive.sh
#
# Purpose: Pre-starts a Claude.ai usage window by sending a lightweight ping
# via the `claude` CLI every N minutes. Since the ~4-5 hour usage limit window
# only begins on the *first* message, this ensures a window is already in
# progress by the time you actually sit down to code. That way when you hit
# your limit and have to wait, the next window may only be 1-2 hours away
# rather than a full 4-5.
#
# Why `claude` CLI and not the raw API?
#   The Anthropic API and Claude.ai Pro are separate billing systems. The
#   `claude` CLI (Claude Code), however, is authenticated against your
#   claude.ai account and shares the same usage session as the web UI.
#
# Requirements:
#   - `claude` CLI installed and logged in (`claude auth login`)
#   - macOS (uses `caffeinate` to prevent Mac sleep during long intervals)
#
# Usage:
#   chmod +x keepalive.sh
#   ./keepalive.sh                              # foreground
#   nohup ./keepalive.sh >> keepalive.log 2>&1 &  # background with log
#   ./keepalive.sh &; disown                    # background, detached
#
# To stop:
#   pkill -f keepalive.sh
# =============================================================================

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Interval between pings in minutes. Ideally just under the usage window
# duration so you're always triggering a fresh window before the old one
# would have naturally expired. 30 minutes is a safe default.
INTERVAL_MINUTES=30
INTERVAL_SECONDS=$(( INTERVAL_MINUTES * 60 ))

# The message sent each ping. Kept intentionally trivial so it uses the
# absolute minimum tokens and doesn't clutter any conversation history.
PING_MESSAGE="Hi"

# Model to use for the ping. "haiku" is the cheapest and fastest — the CLI
# accepts short aliases like "haiku", "sonnet", "opus" in addition to full
# model IDs like "claude-haiku-4-5-20251001".
PING_MODEL="haiku"

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

# Confirm the claude CLI is available on PATH.
if ! command -v claude &>/dev/null; then
  echo "[ERROR] 'claude' CLI not found. Install Claude Code and run 'claude auth login'." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helper: send a single non-interactive ping via the claude CLI.
# ---------------------------------------------------------------------------
ping_claude() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] Sending keepalive ping..."

  # -p / --print flag runs claude in non-interactive (print) mode:
  #   - sends a single message and exits
  #   - does not start a persistent conversation
  #   - output goes to stdout, which we suppress since we don't need it
  # 2>&1 captures any error output so we can detect failures.
  local output
  if output=$(claude -p "$PING_MESSAGE" --model "$PING_MODEL" 2>&1); then
    echo "[$timestamp] Ping successful. Usage window is active."
  else
    echo "[$timestamp] Ping failed: $output" >&2
  fi
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
echo "Claude keepalive started."
echo "Pinging every $INTERVAL_MINUTES minutes to keep a usage window active."
echo "Press Ctrl+C to stop, or 'pkill -f keepalive.sh' if backgrounded."
echo ""

while true; do
  # Send the ping immediately on each iteration (including the first).
  ping_claude

  # caffeinate -t prevents the Mac from sleeping for exactly INTERVAL_SECONDS.
  # This ensures the sleep timer actually runs to completion rather than being
  # paused by system sleep, which would defeat the purpose of the interval.
  caffeinate -t "$INTERVAL_SECONDS" sleep "$INTERVAL_SECONDS"
done
