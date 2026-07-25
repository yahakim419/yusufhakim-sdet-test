# Windows PowerShell — stop the local Docker stack.
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$DockerDir = Join-Path $Root "docker"
$ComposeFile = Join-Path $DockerDir "docker-compose.yml"
$EnvFile = Join-Path $DockerDir ".env"
$EnvExample = Join-Path $DockerDir ".env.example"

if (-not (Test-Path $EnvFile)) {
  $EnvFile = $EnvExample
}

Set-Location $Root
docker compose -f $ComposeFile --env-file $EnvFile down

Write-Host "Stack stopped."
