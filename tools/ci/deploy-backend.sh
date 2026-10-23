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
# A separate checkout preserves operator-owned gitlink changes in the primary clone.
umask 077
mkdir -p "$HOME/.gatekeeper-releases"
release_dir=$(mktemp -d "$HOME/.gatekeeper-releases/$deploy_sha.XXXXXX")
git clone --no-hardlinks --no-checkout "$project_dir" "$release_dir"
git -c submodule.recurse=false -C "$release_dir" checkout --detach "$deploy_sha"
test "$(git -C "$release_dir" rev-parse HEAD)" = "$deploy_sha"
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
    -C "$release_dir" \
    submodule update --init --recursive -- gatekeeper-backend
  rm -rf "$credential_dir"
  trap - EXIT
else
  git -C "$release_dir" submodule update --init --recursive -- gatekeeper-backend
fi
expected_backend=$(git -C "$release_dir" rev-parse HEAD:gatekeeper-backend)
test "$(git -C "$release_dir/gatekeeper-backend" rev-parse HEAD)" = "$expected_backend"

for app in gatekeeper-backend gatekeeper-frontend; do
  mkdir -p "$release_dir/$app"
  if [[ -f "$project_dir/$app/.env" ]]; then
    ln -s "$project_dir/$app/.env" "$release_dir/$app/.env"
  fi
done
if [[ -f "$project_dir/.env" ]]; then
  ln -s "$project_dir/.env" "$release_dir/.env"
fi
if project_name=$(docker inspect --type container --format '{{ index .Config.Labels "com.docker.compose.project" }}' gatekeeper-backend 2>/dev/null); then
  if [[ ! "$project_name" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    echo 'The existing backend container has no valid Compose project label.' >&2
    exit 1
  fi
else
  project_name=gatekeeper
fi
compose=(docker compose --project-name "$project_name" -f "$release_dir/docker-compose.yml")

# Existing database and Redis services are prerequisites, not rollout targets.
"${compose[@]}" config --quiet
"${compose[@]}" build backend
"${compose[@]}" up --detach --no-deps --wait --wait-timeout 120 backend
curl --fail --silent --show-error --retry 5 --retry-connrefused \
  --retry-delay 2 --connect-timeout 5 --max-time 10 http://127.0.0.1:10001/health > /dev/null
printf 'Deployed meta %s, backend %s\n' "$deploy_sha" "$expected_backend"
