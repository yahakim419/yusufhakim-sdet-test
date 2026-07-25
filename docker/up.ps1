# Windows PowerShell — start the local Docker stack from the repo root.
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$DockerDir = Join-Path $Root "docker"
$ComposeFile = Join-Path $DockerDir "docker-compose.yml"
$EnvFile = Join-Path $DockerDir ".env"
$EnvExample = Join-Path $DockerDir ".env.example"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Error "Docker is not installed or not on PATH. Install Docker Desktop (WSL2), then retry."
}

docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "Docker daemon is not running. Start Docker Desktop, then retry."
}

if (-not (Test-Path $EnvFile)) {
  Copy-Item $EnvExample $EnvFile
  Write-Host "Created docker/.env from .env.example — edit secrets if needed."
}

Set-Location $Root
docker compose -f $ComposeFile --env-file $EnvFile up --build -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Waiting for API to accept connections..."
$ready = $false
for ($i = 1; $i -le 60; $i++) {
  try {
    # Any HTTP response means Puma is up (may be 500 until migrations run).
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:3001/health" -UseBasicParsing -TimeoutSec 2
    Write-Host "API is listening."
    $ready = $true
    break
  } catch {
    if ($_.Exception.Response) {
      Write-Host "API is listening."
      $ready = $true
      break
    }
    Start-Sleep -Seconds 2
  }
}

if (-not $ready) {
  Write-Error "API did not start in time. Check: docker compose -f docker/docker-compose.yml logs api"
}

Write-Host "Running db:prepare (create/migrate) and db:seed..."
docker compose -f $ComposeFile --env-file $EnvFile exec -T api bundle exec rails db:prepare db:seed
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Verifying API health..."
try {
  $health = Invoke-WebRequest -Uri "http://127.0.0.1:3001/health" -UseBasicParsing -TimeoutSec 5
  if ($health.StatusCode -ne 200) {
    Write-Error "Health check failed after migrate (HTTP $($health.StatusCode))."
  }
} catch {
  Write-Error "Health check failed after migrate. Check: docker compose -f docker/docker-compose.yml logs api"
}

Write-Host ""
Write-Host "Stack is ready:"
Write-Host "  API  http://localhost:3001/health"
Write-Host "  Web  http://localhost:5173"
Write-Host "Stop with: .\docker\down.ps1"
