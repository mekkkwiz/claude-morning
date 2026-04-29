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

Assert-Contains $setupCron '*/5 * * * *' "default cron schedule should ping every 5 minutes"
Assert-Contains $compose 'CLAUDE_MORNING_CRON_SCHEDULE=*/5 * * * *' "docker compose schedule should ping every 5 minutes"
Assert-Contains $ping '2>&1' "ping should capture stderr so CLI failures are visible"
Assert-NotContains $ping '2>/dev/null' "ping should not discard stderr"
Assert-Contains $ping 'jq -e .' "ping should validate JSON before reading fields"
Assert-Contains $ping 'API_ERROR=$(echo "$OUTPUT" | jq -r' "ping should extract structured API error details when JSON is valid"

Write-Host "static tests passed"
