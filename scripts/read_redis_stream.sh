#!/usr/bin/env sh

set -eu

REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_STREAM_KEY="${REDIS_STREAM_KEY:-redis.events}"
LAST_ID="${REDIS_STREAM_START_ID:-0-0}"

while true; do
  RESPONSE="$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --json XREAD BLOCK 1000 COUNT 10 STREAMS "$REDIS_STREAM_KEY" "$LAST_ID" 2>/dev/null || true)"

  if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "null" ] || [ "$RESPONSE" = "(nil)" ]; then
    continue
  fi

  EVENTS="$(printf '%s' "$RESPONSE" | jq -cr 'to_entries[]? | .key as $stream | .value[] | {stream: $stream, id: .[0], fields: ([.[1] | range(0; length; 2) as $i | {key: .[$i], value: .[$i + 1]}] | from_entries)}')"

  if [ -z "$EVENTS" ]; then
    continue
  fi

  printf '%s\n' "$EVENTS"
  NEXT_ID="$(printf '%s\n' "$EVENTS" | tail -n 1 | jq -r '.id // empty')"
  if [ -n "$NEXT_ID" ]; then
    LAST_ID="$NEXT_ID"
  fi
done
