# Raspberry Pi Secure Backend – Final Status & Deployment Guide

Last audited: 2026-02-21
Host (admin path): `milkathedog@100.69.69.19` (`pi-elias` via Tailscale)
Backend path: `/opt/neverhavei`

## 1️⃣ Current Security Status

### A) Network Exposure
- ✔ Already Secure
- `ss -lntp` shows external listeners only on SSH (`0.0.0.0:22`, `[::]:22`).
- `api` is local-only (`127.0.0.1:3000`), no `80/443` listener.
- Postgres is not host-published.
- UFW is active with `deny incoming` and SSH allowed only on `tailscale0`.
- 🔧 Fixed in this run
- Disabled and masked `rpcbind` (`:111`) so non-SSH external listeners are removed.
- Reconfigured `truth-tracker.service` to localhost-only (`127.0.0.1:8000`) and kept it active.
- ⚠ Missing (manual)
- None for this section.

### B) SSH Security
- ✔ Already Secure
- `PubkeyAuthentication yes`.
- 🔧 Fixed in this run
- Applied SSH hardening drop-in: `/etc/ssh/sshd_config.d/99-neverhavei-hardening.conf`
- `PermitRootLogin no`
- `AllowUsers milkathedog`
- `MaxAuthTries 4`
- `LoginGraceTime 30`
- `X11Forwarding no`
- Created `~/.ssh/authorized_keys` with secure permissions.
- Installed + enabled `fail2ban` with active `sshd` jail.
- ⚠ Missing (manual)
- `PasswordAuthentication` remains `yes` by current decision (lockout avoidance).
- Mitigation while password auth stays enabled:
- keep a strong SSH password,
- keep `fail2ban` active,
- keep SSH restricted to Tailscale path only (`tailscale0` rule).

### C) Docker Security
- ✔ Already Secure
- Restart policies are set (`unless-stopped`).
- DB healthcheck present and DB not published to host ports.
- 🔧 Fixed in this run
- Added `security_opt: [no-new-privileges:true]` to `api` and `db`.
- Added API healthcheck.
- Added split networks:
- `backend` (`internal: true`) for app/db internal traffic.
- `egress` for API outbound internet access (e.g., Groq).
- DB remains internal-only (`db ports={}`).
- ⚠ Missing (manual)
- None for this section.

### D) Fastify/API Security
- ✔ Already Secure
- Input validation already present via `zod`.
- 🔧 Fixed in this run
- Added global HTTP rate limiting (`@fastify/rate-limit`).
- Added strict route rate limit on `/auth/anon` (429 confirmed in test).
- Added explicit body size limit (`BODY_LIMIT_BYTES`, default 1 MiB).
- Replaced permissive CORS with allowlist-based CORS (`CORS_ALLOWED_ORIGINS`).
- Replaced Socket.IO wildcard CORS with allowlist (`SOCKET_ALLOWED_ORIGINS`).
- Added security headers via `@fastify/helmet`.
- Added centralized error handler returning sanitized messages (no stack traces to clients).
- ⚠ Missing (manual)
- Replace localhost CORS allowlists with real production app origins once domain/frontend URLs are final.

### E) Backup System
- ✔ Already Secure
- Backup script exists and cron is configured for daily `04:00`.
- Cron logs to `/var/log/neverhavei-backup.log`.
- 🔧 Fixed in this run
- Updated backup behavior to overwrite single files on USB:
- `postgres_latest.sql`
- `app_latest.tar.gz`
- Added restore script: `/opt/neverhavei/scripts/restore.sh`.
- ⚠ Missing (manual)
- USB mount + restore drill still needs real media test.

### F) Cloudflare Tunnel
- ✔ Already Secure
- Tunnel is active (`cloudflared` service running).
- 🔧 Fixed in this run
- Installed `cloudflared` (`2026.2.0`).
- Created tunnel `neverhavei` (`a57922bf-3d47-404e-96e9-5e9ffcbbfd5b`).
- Routed `api.burk-solutions.de` to the tunnel.
- Installed and enabled `cloudflared` systemd service.
- Updated `/etc/cloudflared/config.yml` with live UUID + ingress to `http://localhost:3000`.
- ⚠ Missing (manual)
- None for this section.

---

## 2️⃣ What Was Secured Now

Delta actions implemented in this run (only missing hardening):

1. Hardened SSH daemon settings and limited login user.
2. Installed and activated `fail2ban` with `sshd` jail.
3. Removed non-essential externally listening `rpcbind` service/socket.
4. Hardened Docker Compose with `no-new-privileges`, API healthcheck, and internal network design.
5. Hardened API runtime with:
- global + strict auth rate limits,
- allowlist CORS (HTTP + WebSocket),
- body size limit,
- security headers,
- sanitized error responses.
6. Upgraded backup design to fixed-file overwrite on USB and added restore script.
7. Installed `cloudflared` and prepared inactive `config.yml` template.
8. Activated Cloudflare Tunnel and verified public API health at `https://api.burk-solutions.de/health`.
9. Migrated operations to Tailscale admin path and removed LAN SSH allowance from UFW.
10. Moved Pi traffic path to Guest WLAN (`wlan0`) and disabled `eth0` for isolation (`denyinterfaces eth0`).
11. Hardened `truth-tracker.service` from public bind (`0.0.0.0:8000`) to localhost-only (`127.0.0.1:8000`).

---

## 3️⃣ Manual Steps Status

### Completed on 2026-02-21

### A) Setup Tailscale SSH
- `tailscaled` active.
- Tailnet SSH verified (`SSH_CONNECTION` from `100.85.57.19` to `100.69.69.19`).

### B) Move Pi to Guest WLAN
- Active WLAN: `Gastzugang Tri` (`wlan0`, `192.168.179.2/24`).
- `eth0` disabled to prevent dual-homing back into home LAN.
- Added `denyinterfaces eth0` in `/etc/dhcpcd.conf` to persist isolation.

### C) Buy Domain at IONOS
- Domain acquired: `burk-solutions.de`.

### D) Move DNS to Cloudflare
- Nameservers switched to Cloudflare and active:
- `candy.ns.cloudflare.com`
- `dilbert.ns.cloudflare.com`

### F) Activate Cloudflare Tunnel
- Tunnel `neverhavei` created and active.
- DNS route active: `api.burk-solutions.de`.
- Public health verified:
```bash
curl -i https://api.burk-solutions.de/health
```

### H) Update App Config
- Updated `app/.env.json` and `app/.env.example.json`:
- `API_URL=https://api.burk-solutions.de`

### Remaining manual items

### E) Configure Email (IONOS MX/SPF/DKIM)
1. Validate MX/SPF/DKIM/DMARC records in Cloudflare.
2. Run mail flow test.

### G) Remove Any Router Port Forwarding
1. Ensure no router forwards for `80/443` to Pi.
2. Ensure SSH is not publicly forwarded.
3. Disable UPnP auto-port-forward for this host.

---

## 4️⃣ Final Security Validation Checklist

Current status (now):
- [x] `docker compose ps` healthy
- [x] `curl http://localhost:3000/health` OK
- [x] `ss` shows no exposed service ports except SSH
- [x] UFW active (`deny incoming`, SSH allowed only on `tailscale0`)
- [x] `fail2ban` active
- [x] Backup script present
- [x] Cloudflared running (`cloudflared` active with 4 tunnel connections)
- [x] Tailscale SSH validated
- [x] Tailscale running on Pi (`tailscaled` active + `tailscale status` logged in)
- [x] Pi isolated in Guest WLAN path (`wlan0` default route, `eth0` disabled)
- [x] Tunnel active and publicly verified (`https://api.burk-solutions.de/health` = 200)
- [x] App production endpoint configured (`app/.env.json`)
- [ ] Router forwarding / UPnP verified in FRITZ!Box UI
- [ ] Email DNS and mail flow validation completed
- [ ] Backup restore tested with real USB media (manual test)

Validation commands:
```bash
sudo docker compose -f /opt/neverhavei/docker-compose.yml ps
curl -sS -i http://localhost:3000/health
ss -lntp
sudo ufw status verbose
sudo systemctl is-active fail2ban
sudo fail2ban-client status
ls -la /opt/neverhavei/scripts/backup.sh /opt/neverhavei/scripts/restore.sh
command -v tailscale
sudo tailscale status
command -v cloudflared
sudo systemctl is-active cloudflared 2>/dev/null || true
curl -sS -i https://api.burk-solutions.de/health | head -n 20
```

---

## 5️⃣ Threat Model Explanation

- No open inbound app ports significantly reduce direct attack surface from the internet.
- Guest WLAN isolation helps prevent lateral movement from the Pi into private LAN devices.
- Cloudflare Tunnel hides direct origin exposure and puts Cloudflare edge controls in front of backend traffic.
- Ongoing maintenance still required: OS/package updates, Docker image updates, key rotation, backup restore drills, and periodic firewall/tunnel audits.

---

## 6️⃣ Emergency Rollback Plan

### Immediate actions
1. Stop tunnel (if enabled later):
```bash
sudo systemctl disable --now cloudflared
```
2. Restore previous compose config on Pi:
```bash
cd /opt/neverhavei
cp docker-compose.yml.bak.20260217_204230 docker-compose.yml
sudo docker compose up -d
```
3. Restore DB/app snapshot from USB (when needed):
```bash
/opt/neverhavei/scripts/restore.sh
```

### SSH fallback rollback
If key-based SSH is confirmed later and password auth is disabled, but rollback is needed:
```bash
sudoedit /etc/ssh/sshd_config.d/99-neverhavei-hardening.conf
# set PasswordAuthentication yes
sudo sshd -t && sudo systemctl reload ssh
```

---

## Current Key Files

- Compose: `/opt/neverhavei/docker-compose.yml`
- Compose backups:
- `/opt/neverhavei/docker-compose.yml.bak.20260217_204230`
- `/opt/neverhavei/docker-compose.yml.bak.20260217_202621`
- SSH hardening: `/etc/ssh/sshd_config.d/99-neverhavei-hardening.conf`
- Fail2ban jail: `/etc/fail2ban/jail.d/sshd.local`
- Cloudflare templates:
- `/etc/cloudflared/config.yml`
- `/etc/cloudflared/config.template.yml`
- Backup scripts:
- `/opt/neverhavei/scripts/backup.sh`
- `/opt/neverhavei/scripts/restore.sh`
- Backup cron: `/etc/cron.d/neverhavei-backup`

---

## Platform Expansion Notes

- Central platform architecture reference: `/Users/eliasburk/Developer/PLATFORM_ARCHITECTURE.md`
- The backend is now organized as a multi-game platform and no longer assumes a single hardcoded game flow.
- All future games must follow the documented game-module pattern (registry entry + isolated module folder + engine/routes/ws registration) without changing platform core components.
