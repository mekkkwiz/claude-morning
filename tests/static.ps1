$ErrorActionPreference = "Stop"

function Assert-Contains {
  param(
    [string] $Text,
    [string] $Expected,
    [string] $Message
  )

  if (-not $Text.Contains($Expected)) {
    throw $Message
  }
}

function Assert-NotContains {
  param(
    [string] $Text,
    [string] $Unexpected,
    [string] $Message
  )

  if ($Text.Contains($Unexpected)) {
    throw $Message
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$setupCron = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "scripts/setup-cron.sh")
$compose = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "docker-compose.yml")
$ping = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "scripts/ping.sh")
$entrypoint = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "entrypoint.sh")
$readme = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "README.md")

Assert-Contains $setupCron '0 8-23/5 * * *' "default cron schedule should ping every 5 hours starting at 8:00"
Assert-Contains $compose 'CLAUDE_MORNING_CRON_SCHEDULE=0 8-23/5 * * *' "docker compose schedule should ping every 5 hours starting at 8:00"
Assert-Contains $ping '2>&1' "ping should capture stderr so CLI failures are visible"
Assert-NotContains $ping '2>/dev/null' "ping should not discard stderr"
Assert-Contains $ping 'jq -e .' "ping should validate JSON before reading fields"
Assert-Contains $ping 'JSON_OUTPUT=$(printf' "ping should extract JSON from mixed stderr/stdout output"
Assert-Contains $ping 'sed -n' "ping should find JSON even when stderr is printed before it"
Assert-Contains $ping 'jq -r ''.api_error_status // .error.message // .error // .message // .result' "ping should prefer structured JSON errors over raw mixed output"
Assert-Contains $ping 'API_ERROR=$(echo "$JSON_OUTPUT" | jq -r' "ping should extract structured API error details when JSON is valid"
Assert-Contains $entrypoint '/root/.claude.json' "entrypoint should handle Claude's root config file"
Assert-Contains $entrypoint '/root/.claude/.claude.json' "entrypoint should keep Claude config in the persisted Claude directory"
Assert-Contains $entrypoint '/root/.claude/backups' "entrypoint should search Claude backups when config is missing"
Assert-Contains $entrypoint ".claude.json.backup.*" "entrypoint should restore Claude config from backup when available"
Assert-Contains $entrypoint 'ln -s "$PERSISTED_CLAUDE_CONFIG" "$CLAUDE_CONFIG"' "entrypoint should link Claude's root config file from persisted storage"
Assert-Contains $readme '/root/.claude.json' "README should document persisting Claude's root config file"

Write-Host "static tests passed"
