#!/bin/sh
LOCKDIR="/tmp/claude-morning-ping.lock"
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")

if ! mkdir "$LOCKDIR" 2>/dev/null; then
  echo "$TIMESTAMP WARN previous ping still running; skipping"
  exit 0
fi
trap 'rmdir "$LOCKDIR"' EXIT INT TERM

STDERR_FILE=$(mktemp)
OUTPUT=$(CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1 \
  CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 \
  CLAUDE_CODE_DISABLE_THINKING=1 \
  ENABLE_CLAUDEAI_MCP_SERVERS=false \
  CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
  claude -p "say ok" --model haiku --system-prompt "" --tools "" --disable-slash-commands --output-format json --setting-sources "" 2>"$STDERR_FILE")
CLAUDE_EXIT_CODE=$?
STDERR_OUTPUT=$(cat "$STDERR_FILE")
rm -f "$STDERR_FILE"

if ! echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
  if [ -n "$STDERR_OUTPUT" ]; then
    echo "$TIMESTAMP ERROR claude-cli: $STDERR_OUTPUT"
  elif [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo "$TIMESTAMP ERROR claude-cli failed with exit code $CLAUDE_EXIT_CODE"
  else
    echo "$TIMESTAMP ERROR invalid JSON response: $OUTPUT"
  fi
  exit 0
fi

IS_ERROR=$(echo "$OUTPUT" | jq -r '.is_error // false')
if [ "$IS_ERROR" = "true" ]; then
  API_ERROR=$(echo "$OUTPUT" | jq -r '.api_error_status // .error // .message // "unknown error"')
  echo "$TIMESTAMP ERROR $API_ERROR"
else
  COST=$(echo "$OUTPUT" | jq -r '.total_cost_usd // "unknown"')
  echo "$TIMESTAMP cost=$COST"
fi

if [ "$1" = "--debug" ]; then
  echo "$OUTPUT" | jq .
fi
