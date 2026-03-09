#!/usr/bin/env bash
set -euo pipefail

PI_HOST="${PI_HOST:-milkathedog@100.69.69.19}"
REMOTE_ROOT="${REMOTE_ROOT:-/opt/neverhavei}"
LOCAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FILES=(
  "api/src/games/never_have_i_ever/engine.ts|backend/src/games/never_have_i_ever/engine.ts"
  "api/src/games/never_have_i_ever/routes.ts|backend/src/games/never_have_i_ever/routes.ts"
  "api/src/games/never_have_i_ever/selectors.ts|backend/src/games/never_have_i_ever/selectors.ts"
  "api/src/game/safety.ts|docs/pi_hotfix_2026_03_03/safety.ts"
  "migrations/004_creator_packs.sql|backend/sql/2026_03_03_creator_packs.sql"
)

echo "Syncing Pi hotfix files from ${PI_HOST}:${REMOTE_ROOT}"

for mapping in "${FILES[@]}"; do
  remote_rel="${mapping%%|*}"
  local_rel="${mapping##*|}"
  local_path="${LOCAL_ROOT}/${local_rel}"
  mkdir -p "$(dirname "${local_path}")"
  scp "${PI_HOST}:${REMOTE_ROOT}/${remote_rel}" "${local_path}"
  echo "  ✓ ${remote_rel} -> ${local_rel}"
done

echo "Done."
