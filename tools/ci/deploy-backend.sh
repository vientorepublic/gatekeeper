#!/usr/bin/env bash
set -euo pipefail

deploy_sha=${1:?A main commit SHA is required}
if [[ ! "$deploy_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Invalid deployment SHA.' >&2
  exit 1
fi

# Serialize server-side deployments, including runs outside GitHub Actions.
exec 9> "$HOME/.gatekeeper-backend-deploy.lock"
flock -w 120 9
cd "$HOME/Gatekeeper"

if [[ "$(git symbolic-ref --short HEAD)" != main ]]; then
  echo 'The server meta checkout must be on main.' >&2
  exit 1
fi
if [[ -n "$(git status --porcelain --ignore-submodules=all)" ]]; then
  echo 'The server meta checkout has local changes.' >&2
  exit 1
fi
if [[ -e gatekeeper-backend/.git ]] &&
  [[ -n "$(git -C gatekeeper-backend status --porcelain)" ]]; then
  echo 'The server backend checkout has local changes.' >&2
  exit 1
fi

git fetch --no-tags origin main
if [[ "$(git rev-parse FETCH_HEAD)" != "$deploy_sha" ]]; then
  echo 'A newer main revision exists; skipping this superseded deployment.'
  exit 0
fi
git merge --ff-only "$deploy_sha"
test "$(git rev-parse HEAD)" = "$deploy_sha"
git submodule update --init --recursive -- gatekeeper-backend
expected_backend=$(git rev-parse HEAD:gatekeeper-backend)
test "$(git -C gatekeeper-backend rev-parse HEAD)" = "$expected_backend"

# Existing database and Redis services are prerequisites, not rollout targets.
docker compose -f docker-compose.yml config --quiet
docker compose -f docker-compose.yml build backend
docker compose -f docker-compose.yml up --detach --no-deps --wait --wait-timeout 120 backend
curl --fail --silent --show-error --retry 5 --retry-connrefused \
  --retry-delay 2 --connect-timeout 5 --max-time 10 http://127.0.0.1:10001/health > /dev/null
printf 'Deployed meta %s, backend %s\n' "$deploy_sha" "$expected_backend"
