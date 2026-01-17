# Deployment Steps

Quick reference for deploying the listonit backend.

## 1. Build & Start Docker Services

```bash
cd /home/ryan/code/listonit
docker compose up -d --build
```

This will:
- Build the backend image with latest code
- Start PostgreSQL and backend containers
- Run database migrations automatically (via entrypoint.sh)

Verify services are running:
```bash
docker compose ps
```

## 2. Seed Users (if needed)

Only required after wiping the database volume:

```bash
python3 docker-seed.py
```

Creates:
- ryan / asdfasdf (admin)
- hanna / asdfasdf

## 3. Start Cloudflare Tunnel

```bash
./cloudflare-tunnel.sh
```

Or manually:
```bash
cloudflared tunnel run listonit
```

## Quick Commands

| Task | Command |
|------|---------|
| Rebuild & restart | `docker compose up -d --build` |
| View logs | `docker logs listonit-backend -f` |
| Restart backend only | `docker compose restart backend` |
| Stop everything | `docker compose down` |
| Check tunnel status | `pgrep -fa cloudflared` |
| Test API | `curl https://api.manyhappyapples.com/` |

## Full Reset

If you need to start fresh:

```bash
docker compose down -v          # Stop and remove volumes
docker compose up -d --build    # Rebuild and start
python3 docker-seed.py          # Re-seed users
./cloudflare-tunnel.sh          # Start tunnel
```
