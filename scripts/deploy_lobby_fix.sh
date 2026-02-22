#!/bin/bash
# deploy_lobby_fix.sh — Deploy lobby fixes to Raspberry Pi
# Run from: /Users/eliasburk/Developer/never_have_i_ever_ai
# Usage: bash scripts/deploy_lobby_fix.sh

set -euo pipefail

PI_HOST="milkathedog@100.69.69.19"
REMOTE_BASE="/opt/neverhavei"
LOCAL_BACKEND="backend/src/games/never_have_i_ever"

echo "=== Lobby Fix Deployment ==="
echo ""

# ─── Step 1: Backup current files on Pi ─────────────
echo "[1/5] Creating backup of current files on Pi..."
ssh "$PI_HOST" "
  cd ${REMOTE_BASE}/api/src/games/never_have_i_ever
  cp ws.ts ws.ts.bak.\$(date +%Y%m%d_%H%M%S)
  cp routes.ts routes.ts.bak.\$(date +%Y%m%d_%H%M%S)
  echo 'Backups created.'
"

# ─── Step 2: Deploy fixed files ─────────────────────
echo ""
echo "[2/5] Uploading fixed ws.ts..."
scp "${LOCAL_BACKEND}/ws.ts" "${PI_HOST}:${REMOTE_BASE}/api/src/games/never_have_i_ever/ws.ts"

echo "[2/5] Uploading fixed routes.ts..."
scp "${LOCAL_BACKEND}/routes.ts" "${PI_HOST}:${REMOTE_BASE}/api/src/games/never_have_i_ever/routes.ts"

# ─── Step 3: Build on Pi ────────────────────────────
echo ""
echo "[3/5] Building TypeScript on Pi..."
ssh "$PI_HOST" "
  cd ${REMOTE_BASE}
  sudo docker compose exec -T api sh -c 'cd /app && npx tsc -p tsconfig.json' 2>/dev/null || {
    echo 'Docker exec build failed, trying direct build...'
    cd ${REMOTE_BASE}/api && npx tsc -p tsconfig.json 2>/dev/null || {
      echo 'Direct build also failed. Will rebuild container.'
    }
  }
"

# ─── Step 4: Restart API container ──────────────────
echo ""
echo "[4/5] Restarting API container..."
ssh "$PI_HOST" "
  cd ${REMOTE_BASE}
  sudo docker compose build api
  sudo docker compose up -d api
  sleep 5
  sudo docker compose ps
"

# ─── Step 5: Health check ───────────────────────────
echo ""
echo "[5/5] Running health check..."
ssh "$PI_HOST" "
  curl -sS http://127.0.0.1:3000/health | python3 -m json.tool 2>/dev/null || curl -sS http://127.0.0.1:3000/health
  echo ''
  echo 'Checking WebSocket readiness...'
  curl -sS http://127.0.0.1:3000/health && echo ' -> API healthy'
"

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Next steps:"
echo "  1. Run canary test: open app, create lobby, join with second device"
echo "  2. Verify: players see each other, game auto-starts at 2 players"
echo "  3. Test: one player leaves → other player sees updated state"
echo "  4. Test: host disconnects → new host is elected"
echo ""
echo "Rollback command:"
echo "  ssh ${PI_HOST} 'cd ${REMOTE_BASE}/api/src/games/never_have_i_ever && cp ws.ts.bak.* ws.ts && cp routes.ts.bak.* routes.ts'"
echo "  ssh ${PI_HOST} 'cd ${REMOTE_BASE} && sudo docker compose build api && sudo docker compose up -d api'"
