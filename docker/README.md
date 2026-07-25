# Local Docker stack (Mac + Windows)

Same Compose file for both OS. Install only **Docker Desktop** (Windows: enable WSL2).

## Quick start

### Mac / Linux

```bash
chmod +x docker/up.sh docker/down.sh docker/api-entrypoint.sh docker/web-entrypoint.sh
./docker/up.sh
```

Stop:

```bash
./docker/down.sh
```

### Windows (PowerShell)

```powershell
.\docker\up.ps1
```

Stop:

```powershell
.\docker\down.ps1
```

## URLs

| Service | URL |
|---------|-----|
| API health | http://localhost:3001/health |
| Web | http://localhost:5173 |

## Configuration

1. Copy `docker/.env.example` → `docker/.env` (the up scripts do this automatically if missing).
2. Set real values when needed:
   - `SECRET_KEY_BASE`
   - `GEMINI_API_KEY`
   - `VITE_DEV_TOKEN` (JWT after API is up)
3. Optional host file `web/.env` (gitignored) for local Vite outside Docker; containers also get `VITE_*` via Compose.

## Manual commands (both OS)

From the **repository root**:

```bash
docker compose -f docker/docker-compose.yml --env-file docker/.env up --build -d
docker compose -f docker/docker-compose.yml --env-file docker/.env exec api bundle exec rails db:prepare db:seed
docker compose -f docker/docker-compose.yml --env-file docker/.env down
```

## Notes

- Does **not** change existing project files (including `api/Dockerfile`).
- Postgres data uses a named Docker volume (portable across Mac/Windows).
- Keep host Postgres/Redis stopped if they bind `5432` / `6379`.
- Web uses file-watch polling so HMR works under Docker Desktop on Windows.
