#!/bin/sh
# Claude Code status line command for agent-meter.
# Needs curl and jq. Set AGENT_METER_URL (the server's address) and AGENT_METER_TOKEN
# (a machine token). Set AGENT_METER_WRAP to a command to keep an existing status line:
# the original input is piped to it and its output is printed.

input=$(cat)

if [ -n "${AGENT_METER_URL:-}" ] && [ -n "${AGENT_METER_TOKEN:-}" ]; then
  stamp="${XDG_CACHE_HOME:-$HOME/.cache}/agent-meter/last-post"
  mkdir -p "$(dirname "$stamp")"
  now=$(date +%s)
  last=$(stat -c %Y "$stamp" 2>/dev/null || stat -f %m "$stamp" 2>/dev/null || echo 0)
  if [ $((now - last)) -ge 60 ]; then
    # Only the session id and rate_limits leave the machine; the input also holds local paths.
    payload=$(printf '%s' "$input" | jq -c 'select(.rate_limits != null) | {session_id, rate_limits}' 2>/dev/null)
    if [ -n "$payload" ]; then
      touch "$stamp"
      (curl -s -m 2 -o /dev/null -X POST "$AGENT_METER_URL/api/quota/statusline" \
        -H "Authorization: Bearer $AGENT_METER_TOKEN" -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1 &)
    fi
  fi
fi

if [ -n "${AGENT_METER_WRAP:-}" ]; then
  printf '%s' "$input" | sh -c "$AGENT_METER_WRAP"
else
  printf '%s' "$input" | jq -r '[
    (.rate_limits.five_hour.used_percentage // empty | "5h \(floor)%"),
    (.rate_limits.seven_day.used_percentage // empty | "7d \(floor)%")
  ] | join(" · ")'
fi
