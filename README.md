# claude-morning

A lightweight Docker container that runs Claude Code on a daily schedule to keep your Claude subscription session active.

## How it works

- Runs as a persistent container (24/7) via Docker Compose
- A cron job fires `claude -p "ping"` starting at 8AM then every 5 hours (8, 13, 18, 23) using Haiku (minimal cost)
- Auth state is persisted in `./data/` so you only log in once
- Logs timestamp and cost to stdout on each run

## Usage

### Option A: Pull from GHCR (recommended)

Create a `docker-compose.yml`:

```yaml
services:
  claude-morning:
    image: ghcr.io/narze/claude-morning:latest
    volumes:
      - claude-data:/root/.claude
    command: daemon
    environment:
      - CLAUDE_MORNING_CRON_SCHEDULE=0 8-23/5 * * *
      - TZ=Asia/Bangkok
    restart: unless-stopped

volumes:
  claude-data:
```

Then:

```bash
docker compose up -d
docker compose exec -it claude-morning claude
# log in from within the TUI
```

### Option B: Build from source

```bash
git clone https://github.com/narze/claude-morning
cd claude-morning
docker compose build
docker compose up -d
docker compose exec -it claude-morning claude
# log in from within the TUI
```

### Option C: Deploy to Railway

1. **Create Project**: Fork this repository or push it to your GitHub account and [Deploy to Railway](https://railway.app/new).
2. **Add Volume**: In your Railway dashboard, go to the **Volumes** tab and add a new volume. Mount it to `/root/.claude`. This is required to keep your login state persistent across deployments.
3. **Environment Variables**: In the **Variables** tab, set `CLAUDE_MORNING_CRON_SCHEDULE` and `TZ`.
4. **Authenticate**: Install the [Railway CLI](https://docs.railway.app/guides/cli), then run `railway shell` in your terminal to access the container, and type `claude` to log in.


## Configuration

| Environment variable         | Default           | Description                     |
|------------------------------|-------------------|---------------------------------|
| `CLAUDE_MORNING_CRON_SCHEDULE`| `0 8-23/5 * * *`  | Cron schedule (comma-separated for multiple, e.g. `0 8-23/5 * * *` or `0 8 * * *,0 20 * * *`) |
| `TZ`                    | (none/UTC)        | Timezone (e.g. `Asia/Bangkok`)   |

## Examples

### Run starting at 8 AM then every 5 hours in Tokyo timezone

```yaml
environment:
  - CLAUDE_MORNING_CRON_SCHEDULE=0 8-23/5 * * *
  - TZ=Asia/Tokyo
```

## Useful commands

```bash
# Check cron is configured correctly
docker compose exec claude-morning cat /etc/crontabs/root

# Tail the ping log
docker compose exec claude-morning tail -f /var/log/claude-ping.log

# Run ping manually
docker compose exec claude-morning /scripts/ping.sh

# Run ping with full JSON output
docker compose exec claude-morning /scripts/ping.sh --debug

# Re-authenticate
docker compose exec -it claude-morning claude
```

## Development

```bash
git clone https://github.com/narze/claude-morning
cd claude-morning
docker compose build
docker compose up -d

# Test the ping script
docker compose exec claude-morning /scripts/ping.sh --debug
```

## Files

```
Dockerfile            — node:24-alpine + jq + claude-code
entrypoint.sh         — daemon mode runs crond; otherwise passes args to claude
scripts/ping.sh       — runs claude -p "ping" and logs timestamp + cost
scripts/setup-cron.sh — writes crontab from $CLAUDE_MORNING_CRON_SCHEDULE
data/                 — persisted Claude auth state (gitignored)
```
