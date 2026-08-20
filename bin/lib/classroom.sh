#!/usr/bin/env bash
#
# Shared helpers for the bin/ scripts. Source, do not execute.

readonly SERVER_CONTAINER=openvox-server

error() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_running() {
  local container="$1"
  local state

  command -v docker >/dev/null 2>&1 ||
    error "'docker' is not on PATH. Run this from the dev container's terminal,
    or from a machine with Docker installed."

  state="$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null)" ||
    error "container '${container}' does not exist. Start the lab with:
    docker compose -f .devcontainer/docker-compose.yml up -d"

  if [ "$state" != "running" ]; then
    error "container '${container}' is ${state}, not running. Try: docker start ${container}"
  fi
}

# enter <container> [command...]
#
# Runs a command in a container, or opens an interactive shell when given none.
# Adds --tty only when there is a terminal on both ends, so piping the output
# (`bin/alma puppet agent -t | tee run.log`) still works.
enter() {
  local container="$1"
  shift

  require_running "$container"

  local -a opts=(--interactive)
  # Check if stdin (0) and stdout (1) are real terminals
  if [ -t 0 ] && [ -t 1 ]; then
    opts+=(--tty)
  fi

  # For bin/server, if --root is specified, EXEC_USER=root is set
  if [ -n "${EXEC_USER:-}" ]; then
    opts+=(--user "$EXEC_USER")
  fi

  if [ "$#" -eq 0 ]; then
    set -- bash
  fi

  exec docker exec "${opts[@]}" "$container" "$@"
}
