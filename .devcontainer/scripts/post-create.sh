#!/usr/bin/env bash
#
# Runs once, after the devcontainer is created, to start and setup the lab.

set -uo pipefail

readonly TIMEOUT_SECONDS=600

log() { printf '%s\n' "$*"; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

if ! bash "${script_dir}/lab-up.sh"; then
  log ""
  log "The lab containers did not start. Try again with:"
  log "    bash .devcontainer/scripts/lab-up.sh"
  log "and check the daemon with 'docker info'"
  exit 0
fi

has_cert() {
  docker exec "$1" test -f "/etc/puppetlabs/puppet/ssl/certs/$2.pem" 2>/dev/null
}

log "Waiting for the agents to get a cert from the OpenVox server..."

deadline=$((SECONDS + TIMEOUT_SECONDS))
while [ "$SECONDS" -lt "$deadline" ]; do
  if has_cert agent-alma alma.example.com && has_cert agent-ubuntu ubuntu.example.com; then
    ready=yes
    break
  fi
  sleep 5
done

if [ "${ready:-no}" != yes ]; then
  log ""
  log "The agents have not got certificates yet after ${TIMEOUT_SECONDS}s."
  log "The lab may just be slow on first boot. To see what is happening:"
  log "    docker logs -f agent-alma"
  log "    bin/status"
  exit 0
fi

log ""
docker exec openvox-server puppetserver ca list --all 2>/dev/null || true
log ""
log "OpenVox classroom is ready."
log ""
log "  Edit Puppet code in   code/environments/production/"
log "                        (the server sees it live at /etc/puppetlabs/code)"
log ""
log "  Shell into a target   bin/alma"
log "                        bin/ubuntu"
log "  Shell into the server bin/server"
log ""
log "  Apply a catalog       bin/alma puppet agent -t"
log "  Check the lab         bin/status"
log ""
