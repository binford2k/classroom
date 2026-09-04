#!/usr/bin/env bash
#
# Installs the OpenVox agent on a stock distro image, gets a cert from the server,
# then hands off to systemd so the target can run services.
#
# Runs on every container start. The install is skipped if the agent is already
# present, so `docker restart agent-alma` is fast while
# `docker compose up --force-recreate` gets a clean install of the latest agent.

set -euo pipefail

: "${OPENVOX_COLLECTION:=openvox8}"
: "${OPENVOX_AGENT_VERSION:=}"
: "${OPENVOX_SERVER:=server.example.com}"
: "${CERTNAME:=${HOSTNAME}}"

readonly PUPPET_BIN=/opt/puppetlabs/bin/puppet

log() { printf '[classroom] %s\n' "$*"; }

source /etc/os-release

install_agent_el() {
  local major="${VERSION_ID%%.*}"
  local package='openvox-agent'
  if [ -n "$OPENVOX_AGENT_VERSION" ]; then
    package="openvox-agent-${OPENVOX_AGENT_VERSION}"
  fi

  log "Installing ${OPENVOX_COLLECTION} release package for el-${major}"
  dnf install -y "https://yum.voxpupuli.org/${OPENVOX_COLLECTION}-release-el-${major}.noarch.rpm"

  log "Installing ${package}"
  dnf install -y "$package"

  dnf install -y less vim iproute util-linux procps openssl

  # required for Apache SSL to start properly
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/pki/tls/private/localhost.key      \
      -out /etc/pki/tls/certs/localhost.crt           \
      -subj "/C=US/ST=Oregon/L=Portland/O=Example/CN=localhost"
}

install_agent_deb() {
  local suite="${ID}${VERSION_ID}"
  local package='openvox-agent'
  if [ -n "$OPENVOX_AGENT_VERSION" ]; then
    package="openvox-agent=${OPENVOX_AGENT_VERSION}-1+${suite}"
  fi

  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  # The stock ubuntu image has neither curl nor CA certificates, so the release
  # package cannot be fetched until these are in place.
  apt-get install -y --no-install-recommends ca-certificates curl

  log "installing ${OPENVOX_COLLECTION} release package for ${suite}"
  curl -fsSL -o /tmp/openvox-release.deb \
    "https://apt.voxpupuli.org/${OPENVOX_COLLECTION}-release-${suite}.deb"
  dpkg -i /tmp/openvox-release.deb
  rm -f /tmp/openvox-release.deb
  apt-get update

  log "Installing ${package}"
  apt-get install -y "$package"

  apt-get install -y --no-install-recommends less vim iproute2

  # The stock ubuntu image has no init system. The AlmaLinux target uses an
  # image that already ships systemd and a D-Bus broker, so only Ubuntu needs
  # this.
  apt-get install -y --no-install-recommends systemd dbus
}

if [ -x "$PUPPET_BIN" ]; then
  log "openvox-agent already installed, skipping install"
else
  case "$ID" in
    almalinux | rocky | rhel | centos | fedora) install_agent_el ;;
    ubuntu | debian) install_agent_deb ;;
    *)
      log "Unsupported distribution '${ID}'. Add support to bootstrap-agent.sh for this OS."
      exit 1
      ;;
  esac
fi

echo 'export PATH=/opt/puppetlabs/bin:$PATH' >/etc/profile.d/openvox-classroom.sh

log "Setting server to ${OPENVOX_SERVER} and certname to ${CERTNAME}"
"$PUPPET_BIN" config set server "$OPENVOX_SERVER" --section main
"$PUPPET_BIN" config set certname "$CERTNAME" --section main

log "Waiting for ${OPENVOX_SERVER} to come up"
for ((attempt = 0; attempt < 90; attempt++)); do
  server_status="$(curl -sk --max-time 5 "https://${OPENVOX_SERVER}:8140/status/v1/simple" || true)"
  if [ "$server_status" = running ]; then
    log "Server is running"
    break
  fi
  sleep 1
done

log "Requesting certificate for ${CERTNAME}"
"$PUPPET_BIN" ssl bootstrap --waitforcert 10 --maxwaitforcert 600

log "Ready!"

exec /usr/lib/systemd/systemd
