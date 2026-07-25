# The Platform

A two-service application used for the Quality Engineer case study. It is provided as a single repository so the whole thing clones, runs, and releases as one unit.

```
.
├── api/     # Backend service (Ruby on Rails, PostgreSQL, Redis/Sidekiq)
├── web/     # Frontend web app (React 18 + TypeScript, Vite, Tailwind)
└── docker/  # Local Docker Compose stack (Mac + Windows)
```

The two services run together: the web app talks to the API over REST and WebSocket.

## Running it locally

### With Docker (recommended)

**Prerequisites**

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Windows: enable WSL2
- Free host ports `3001`, `5173`, `5432`, and `6379` (stop local Postgres/Redis if they conflict)

**Start** (from the repository root)

Mac / Linux:

```bash
chmod +x docker/up.sh docker/down.sh docker/api-entrypoint.sh docker/web-entrypoint.sh
./docker/up.sh
```

Windows (PowerShell):

```powershell
.\docker\up.ps1
```

The up scripts create `docker/.env` from `docker/.env.example` if missing, build and start the stack, run `db:prepare` and `db:seed`, then print ready URLs.

**URLs**

| Service | URL |
|---------|-----|
| API health | http://localhost:3001/health |
| Web | http://localhost:5173 |

**Stop**

Mac / Linux: `./docker/down.sh`

Windows (PowerShell): `.\docker\down.ps1`

**Optional configuration**

Edit `docker/.env` when you need real values for `SECRET_KEY_BASE`, `GEMINI_API_KEY`, or `VITE_DEV_TOKEN`. See [`docker/README.md`](docker/README.md) for manual Compose commands and extra notes.

### Without Docker

Each service has its own setup guide. Run the API first, then the web app pointed at it.

1. **API** — see [`api/README.md`](api/README.md). Rails app; needs Ruby (see `api/.ruby-version`), PostgreSQL, and Redis. It serves on `http://localhost:3001`.
2. **Web** — see [`web/README.md`](web/README.md). Vite app; `npm install`, copy `.env.example` to `.env`, point `VITE_API_BASE_URL` at the API, then `npm run dev`. It serves on `http://localhost:5173`.

## Notes for the case study

- This is the codebase you assess, harden, and release. Treat it as a version about to ship to a client.
- Work in the `/assessment` folder at the repo root for your written deliverables; code changes go in `api/` or `web/`.
- See the case-study brief you were given for what to produce and how it is evaluated.
