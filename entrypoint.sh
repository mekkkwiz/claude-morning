#!/bin/sh
if [ "$TZ" != "" ]; then
  echo "Timezone: $TZ"
fi

CLAUDE_CONFIG="/root/.claude.json"
PERSISTED_CLAUDE_CONFIG="/root/.claude/.claude.json"
CLAUDE_CONFIG_BACKUP=$(find /root/.claude/backups -maxdepth 1 -name '.claude.json.backup.*' -type f 2>/dev/null | sort | tail -n 1)

if [ ! -f "$PERSISTED_CLAUDE_CONFIG" ] && [ "$CLAUDE_CONFIG_BACKUP" != "" ]; then
  cp "$CLAUDE_CONFIG_BACKUP" "$PERSISTED_CLAUDE_CONFIG"
  echo "Restored Claude config from $CLAUDE_CONFIG_BACKUP"
fi

if [ ! -e "$CLAUDE_CONFIG" ] && [ ! -L "$CLAUDE_CONFIG" ]; then
  ln -s "$PERSISTED_CLAUDE_CONFIG" "$CLAUDE_CONFIG"
fi

if [ "$1" = "daemon" ]; then
  /scripts/setup-cron.sh
  exec crond -f -l 8
elif [ "$1" = "once" ]; then
  exec /scripts/ping.sh
else
  exec claude "$@"
fi
