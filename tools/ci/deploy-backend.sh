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
project_dir="$HOME/Gatekeeper"
if [[ ! -d "$project_dir" ]]; then
  project_dir=''
  while IFS= read -r candidate; do
    if [[ -e "$candidate/.git" && -f "$candidate/docker-compose.yml" ]]; then
      if [[ -n "$project_dir" ]]; then
        echo 'Multiple Gatekeeper checkouts found; configure a unique deployment checkout.' >&2
        exit 1
      fi
      project_dir="$candidate"
    fi
  done < <(find "$HOME" -mindepth 1 -maxdepth 3 -type d -iname gatekeeper -print)
  if [[ -z "$project_dir" ]]; then
    echo 'No Gatekeeper Git/Compose checkout found under the root home directory.' >&2
    find "$HOME" -mindepth 1 -maxdepth 3 -type d -iname '*gatekeeper*' -print >&2
    exit 1
  fi
fi
cd "$project_dir"
printf 'Deployment checkout: %s\n' "$project_dir"

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

if [[ -n "${GATEKEEPER_FETCH_TOKEN:-}" ]]; then
  # Keep the short-lived root repository token out of Git configuration and arguments.
  git -c credential.helper= \
    -c 'credential.helper=!f() { printf "%s\n" "username=x-access-token" "password=$GATEKEEPER_FETCH_TOKEN"; }; f' \
    fetch --recurse-submodules=no --no-tags origin main
else
  git fetch --recurse-submodules=no --no-tags origin main
fi
unset GATEKEEPER_FETCH_TOKEN
if [[ "$(git rev-parse FETCH_HEAD)" != "$deploy_sha" ]]; then
  echo 'A newer main revision exists; skipping this superseded deployment.'
  exit 0
fi
git -c submodule.recurse=false merge --ff-only "$deploy_sha"
test "$(git rev-parse HEAD)" = "$deploy_sha"
if [[ -n "${GATEKEEPER_BACKEND_READ_KEY:-}" ]]; then
  : "${GATEKEEPER_GITHUB_HOST_KEYS:?Verified GitHub SSH host keys are required}"
  umask 077
  credential_dir=$(mktemp -d)
  trap 'rm -rf "$credential_dir"' EXIT
  printf '%s\n' "$GATEKEEPER_BACKEND_READ_KEY" > "$credential_dir/backend-key"
  printf '%s\n' "$GATEKEEPER_GITHUB_HOST_KEYS" > "$credential_dir/known_hosts"
  unset GATEKEEPER_BACKEND_READ_KEY GATEKEEPER_GITHUB_HOST_KEYS
  git -c url.ssh://git@github.com/.insteadOf=https://github.com/ \
    -c "core.sshCommand=ssh -i $credential_dir/backend-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$credential_dir/known_hosts" \
    submodule update --init --recursive -- gatekeeper-backend
  rm -rf "$credential_dir"
  trap - EXIT
else
  git submodule update --init --recursive -- gatekeeper-backend
fi
expected_backend=$(git rev-parse HEAD:gatekeeper-backend)
test "$(git -C gatekeeper-backend rev-parse HEAD)" = "$expected_backend"

# Existing database and Redis services are prerequisites, not rollout targets.
docker compose -f docker-compose.yml config --quiet
docker compose -f docker-compose.yml build backend
docker compose -f docker-compose.yml up --detach --no-deps --wait --wait-timeout 120 backend
curl --fail --silent --show-error --retry 5 --retry-connrefused \
  --retry-delay 2 --connect-timeout 5 --max-time 10 http://127.0.0.1:10001/health > /dev/null
printf 'Deployed meta %s, backend %s\n' "$deploy_sha" "$expected_backend"
