#!/usr/bin/env bash
# Installed with a trusted PATH by Nix writeShellApplication.
set -euo pipefail
umask 077
# Keep recovery messages visible even when cancellation arrives during a quiet probe.
exec 3>&2

log() {
  printf 'bosla-deploy: %s\n' "$*" >&3
}

fail() {
  log "$*"
  exit 1
}

[[ "$#" -eq 2 ]] || fail 'usage: bosla-deploy <api|frontend|typst-worker|pipeline> <full-commit-sha>'
[[ "$(id -u)" == 0 ]] || fail 'must run as root'
[[ "$2" =~ ^[0-9a-f]{40}$ ]] || fail 'commit must be exactly 40 lowercase hexadecimal characters'
unset DOCKER_HOST DOCKER_CONTEXT DOCKER_CONFIG DOCKER_TLS DOCKER_TLS_VERIFY DOCKER_CERT_PATH DOCKER_API_VERSION

service="$1"
commit="$2"
case "$service" in
  api)
    repository=bosla26/bosla-api
    container=bosla-api
    ;;
  frontend)
    repository=bosla26/bosla-frontend
    container=bosla-frontend
    ;;
  typst-worker)
    repository=bosla26/typst-worker
    container=typst-worker
    ;;
  pipeline)
    repository=bosla26/bosla-pipeline
    container=bosla-pipeline
    ;;
  *) fail 'unsupported service' ;;
esac
unit="docker-${container}.service"
if [[ "$service" == pipeline ]]; then unit="bosla-pipeline.service"; fi
image_ref="${repository}:${commit}"
latest_ref="${repository}:latest"
rollback_needed=0

# Never inherit a caller's Docker context, daemon, or credential directory.
# Every external command is resolved through the Nix package's trusted PATH.
docker_local() {
  local duration="$1"
  shift
  timeout --signal=TERM --kill-after=5s "$duration" \
    docker --host=unix:///var/run/docker.sock --config=/root/.docker "$@"
}

restart_service() {
  timeout --signal=TERM --kill-after=5s 90s systemctl --system restart "$unit"
}

probe() {
  case "$service" in
    api)
      docker_local 10s exec "$container" \
        curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8080/api/health
      ;;
    frontend)
      docker_local 10s exec "$container" \
        wget --quiet --spider --timeout=5 http://127.0.0.1/
      ;;
    typst-worker)
      docker_local 10s exec "$container" \
        curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8080/healthz
      ;;
    pipeline)
      docker_local 10s exec "$container" \
        curl --fail --silent --show-error --max-time 5 http://127.0.0.1:7860/health
      ;;
  esac
}

wait_ready() {
  local expected_image="$1"
  local deadline=$((SECONDS + 150))
  local attempt state
  for ((attempt = 1; attempt <= 30 && SECONDS < deadline; attempt++)); do
    state=$(docker_local 10s inspect --format '{{.Image}} {{.State.Running}}' "$container" 2>/dev/null) || state=unavailable
    if [[ "$state" == "$expected_image true" ]] && probe >/dev/null 2>&1; then
      log "$container is ready on image $expected_image"
      return 0
    fi
    log "waiting for $container to run the requested image and pass HTTP readiness ($attempt/30)"
    if ((attempt < 30 && SECONDS < deadline)); then
      sleep 5
    fi
  done
  return 1
}

on_exit() {
  local status="$?"
  trap - EXIT
  # A second cancellation must not interrupt recovery. SIGKILL cannot be caught.
  trap '' INT TERM HUP
  if ((rollback_needed)); then
    ((status != 0)) || status=1
    log "deployment failed; restoring $container to $original_image"
    if docker_local 30s tag "$original_image" "$latest_ref" \
      && restart_service \
      && wait_ready "$original_image"; then
      log "rollback completed for $container"
    else
      log "ROLLBACK FAILED for $container; preserved image $original_image remains tagged $rollback_ref"
    fi
  fi
  exit "$status"
}

trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# Append mode avoids truncating any existing file. /run/lock is host owned.
exec 9>>/run/lock/bosla-deploy.lock
flock --exclusive --wait 600 9 || fail 'another Bosla deployment still holds the lock'

# Refuse a first deployment: there must be a known container image to restore.
original_image=$(docker_local 30s inspect --format '{{.Image}}' "$container") \
  || fail "existing container $container is missing; no rollback baseline"
[[ "$original_image" =~ ^sha256:[0-9a-f]{64}$ ]] || fail 'existing container has no valid image ID'

log "pulling $image_ref; current image is $original_image"
docker_local 300s pull "$image_ref"
image_metadata=$(docker_local 30s image inspect --format '{{.Id}} {{.Architecture}} {{.Os}}' "$image_ref")
read -r desired_image image_arch image_os <<<"$image_metadata"
[[ "$desired_image" =~ ^sha256:[0-9a-f]{64}$ ]] || fail 'pulled image has no valid image ID'
[[ "$image_arch" == arm64 && "$image_os" == linux ]] || fail "expected linux/arm64 image, received $image_os/$image_arch"

rollback_ref="${repository}:rollback-$(date -u +%Y%m%dT%H%M%S)-$$"
docker_local 30s tag "$original_image" "$rollback_ref"

# Arm recovery before changing latest, including cancellation during docker tag.
# NixOS must use pull=never so restart consumes this local, pinned image.
rollback_needed=1
docker_local 30s tag "$desired_image" "$latest_ref"
log "restarting $unit with image $desired_image"
restart_service
wait_ready "$desired_image" || fail "$container did not become ready on the requested image"
rollback_needed=0
log "deployed $image_ref as $desired_image; rollback image retained as $rollback_ref"
