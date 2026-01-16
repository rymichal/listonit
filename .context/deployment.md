# Home Server Deployment Plan

Simple deployment for personal use on a home server with Cloudflare tunnel.

## Architecture

```
Internet → Cloudflare Tunnel → Backend (FastAPI :8000) → PostgreSQL (:5432)
```

## Prerequisites

- Docker and Docker Compose installed
- Cloudflare account with a registered domain
- `cloudflared` installed on the server

## Step 1: Configure Environment

Create `/home/ryan/code/listonit/backend/.env`:

```bash
# Copy from example and modify
cp backend/.env.example backend/.env
```

Edit `.env`:
```bash
DATABASE_URL=postgresql://listonit:YOUR_SECURE_PASSWORD@postgres:5432/listonit
JWT_SECRET_KEY=<generate with: openssl rand -hex 32>
CORS_ORIGINS=["https://yourdomain.com"]
DEBUG=false
```

## Step 2: Update docker-compose.yml

Update the postgres password and CORS origins to match your domain:

```yaml
# In postgres service:
POSTGRES_PASSWORD: YOUR_SECURE_PASSWORD

# In backend service:
DATABASE_URL: postgresql://listonit:YOUR_SECURE_PASSWORD@postgres:5432/listonit
CORS_ORIGINS: '["https://yourdomain.com"]'
```

Remove redis service if not actively used (current backend doesn't require it).

## Step 3: Start Services

```bash
cd /home/ryan/code/listonit
docker compose up -d
```

Verify:
```bash
curl http://localhost:8000/
# Should return: {"status":"ok"}
```

## Step 4: Set Up Cloudflare Tunnel

1. **Create tunnel** (one-time):
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create listonit
   ```

2. **Create config** at `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <TUNNEL_ID>
   credentials-file: /home/ryan/.cloudflared/<TUNNEL_ID>.json

   ingress:
     - hostname: api.yourdomain.com
       service: http://localhost:8000
     - service: http_status:404
   ```

3. **Add DNS record**:
   ```bash
   cloudflared tunnel route dns listonit api.yourdomain.com
   ```

4. **Run tunnel**:
   ```bash
   cloudflared tunnel run listonit
   ```

## Step 5: Run Tunnel as Service (Optional)

```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

## Maintenance

**View logs:**
```bash
docker compose logs -f backend
```

**Restart services:**
```bash
docker compose restart
```

**Update and rebuild:**
```bash
git pull
docker compose up -d --build
```

**Database backup:**
```bash
docker exec listonit-postgres pg_dump -U listonit listonit > backup.sql
```

## Checklist

- [ ] Generate secure JWT_SECRET_KEY
- [ ] Set strong postgres password
- [ ] Update CORS_ORIGINS with your domain
- [ ] Cloudflare tunnel created and configured
- [ ] DNS record pointing to tunnel
- [ ] Services running and healthy
