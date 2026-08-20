#!/usr/bin/env bash
#
# Brings the lab containers up on the devcontainer's inner Docker daemon.

set -euo pipefail

compose_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.yml"

log() { printf '[lab-up] %s\n' "$*"; }

# The docker-in-docker feature starts its daemon in the background as the
# container comes up, so losing this race on the first call is normal.
attempts_left=30
until docker info >/dev/null 2>&1; do
  attempts_left=$((attempts_left - 1))
  if [ "$attempts_left" -eq 0 ]; then
    log "The Docker daemon did not come up after 60 seconds."
    log "Check /tmp/dockerd.log for details, if it exists."
    exit 1
  fi
  sleep 2
done

log "Starting the lab"
docker compose -f "$compose_file" up -d
