#!/bin/sh
OUTPUT=$(CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1 CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 CLAUDE_CODE_DISABLE_THINKING=1 ENABLE_CLAUDEAI_MCP_SERVERS=false CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude -p "say ok" --model haiku --system-prompt "" --tools "" --disable-slash-commands --output-format json --setting-sources "" 2>&1)
STATUS=$?
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")

if ! echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
  ERROR_MESSAGE=$(printf '%s' "$OUTPUT" | tr '\n' ' ' | sed 's/[[:space:]][[:space:]]*/ /g')
  if [ "$ERROR_MESSAGE" = "" ]; then
    ERROR_MESSAGE="claude exited with status $STATUS without output"
  fi
  echo "$TIMESTAMP ERROR claude_exit=$STATUS message=$ERROR_MESSAGE"
elif [ "$(echo "$OUTPUT" | jq -r '.is_error')" = "true" ] || [ "$STATUS" -ne 0 ]; then
  API_ERROR=$(echo "$OUTPUT" | jq -r '.api_error_status // .error.message // .error // .message // .result // "Claude returned an error without details"')
  echo "$TIMESTAMP ERROR $API_ERROR"
else
  COST=$(echo "$OUTPUT" | jq -r '.total_cost_usd')
  echo "$TIMESTAMP cost=$COST"
fi

if [ "$1" = "--debug" ]; then
  echo "$OUTPUT" | jq .
fi
