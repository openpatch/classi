# Classi Backend – Self-hosted Supabase + PowerSync

This folder contains a Docker Compose setup that runs the full Classi backend
locally (or on your own server): **Supabase** (PostgreSQL + GoTrue auth +
PostgREST) and **PowerSync** (real-time sync service).

```
backend/
├── docker-compose.yml          # All services
├── .env.example                # Environment variable template
├── powersync.yaml              # PowerSync service config
├── sync-rules.yaml             # PowerSync sync rules (per-user buckets)
└── volumes/
    ├── kong.yml                # Kong API-gateway declarative config
    └── db/
        └── init/
            └── 01-classi-schema.sql  # Classi table definitions + RLS
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and
  [Docker Compose](https://docs.docker.com/compose/install/) v2+

## Quick Start

### 1. Configure environment variables

```bash
cp .env.example .env
```

Open `.env` and set **at minimum**:

| Variable | Description |
|---|---|
| `POSTGRES_PASSWORD` | Strong password for PostgreSQL |
| `JWT_SECRET` | ≥ 32-character secret shared by Supabase and PowerSync |
| `ANON_KEY` | JWT signed with `JWT_SECRET` and `role: anon` |
| `SERVICE_ROLE_KEY` | JWT signed with `JWT_SECRET` and `role: service_role` |

> **Generating JWTs**: Use the
> [Supabase JWT generator](https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys)
> or run:
> ```bash
> # Install jwt-cli if needed: brew install mike-engel/jwt-cli/jwt-cli
> jwt encode --secret "your-jwt-secret" '{"role":"anon","iat":1613531985,"exp":4769205985}'
> jwt encode --secret "your-jwt-secret" '{"role":"service_role","iat":1613531985,"exp":4769205985}'
> ```

### 2. Start all services

```bash
docker compose up -d
```

This starts:

| Service | Port | Description |
|---|---|---|
| `db` | 5432 | PostgreSQL |
| `auth` | 9999 | Supabase GoTrue (authentication) |
| `rest` | 3000 | PostgREST (REST API) |
| `kong` | 8000 | API gateway (public entry point) |
| `studio` | 3000 | Supabase Studio dashboard |
| `meta` | 8080 | Postgres metadata API |
| `inbucket` | 9000 | Local email server (dev only) |
| `powersync` | 8080 | PowerSync sync service |

### 3. Verify services are healthy

```bash
docker compose ps
```

All services should show **running**. Check logs if anything fails:

```bash
docker compose logs -f <service-name>
```

### 4. Register a user

Open the Supabase Studio at **http://localhost:3000** (login:
`supabase` / `this_password_is_insecure_and_should_be_updated`) and create a
user via **Authentication → Users → Add user**, or call the API directly:

```bash
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email":"teacher@example.com","password":"your-password"}'
```

### 5. Configure the Classi app

In the app go to **Settings → Remote Sync** and enter:

| Field | Value |
|---|---|
| Supabase URL | `http://localhost:8000` |
| Supabase Anon Key | Value of `ANON_KEY` from `.env` |
| PowerSync Endpoint | `http://localhost:8080` |

Sign in with the credentials you created in step 4. The app will begin syncing
automatically.

## Email verification (development)

Email confirmation links are delivered to the local **Inbucket** inbox at
**http://localhost:9000**. You can also disable confirmation entirely in `.env`:

```env
ENABLE_EMAIL_AUTOCONFIRM=true
```

## Stopping and resetting

```bash
# Stop without deleting data
docker compose down

# Stop and remove all data volumes (full reset)
docker compose down -v
```

## Production deployment

For a production setup:

1. Replace all default passwords and JWT secrets.
2. Put a reverse proxy (nginx / Caddy / Traefik) with TLS in front of Kong
   (port 8000) and PowerSync (port 8080).
3. Set `SITE_URL` and `ADDITIONAL_REDIRECT_URLS` to your public domain.
4. Consider using a managed PostgreSQL service instead of the containerised `db`.
5. See the
   [Supabase self-hosting guide](https://supabase.com/docs/guides/self-hosting/docker)
   and the
   [PowerSync self-hosting guide](https://docs.powersync.com/self-hosting/getting-started)
   for further hardening advice.
