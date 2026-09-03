# OpenVox Classroom

An ephemeral OpenVox lab: one server generating catalogs andrunning the CA,
and two targets that install the agent, request certificates, and wait for you
to apply a catalog.

Open it in a GitHub Codespace, or locally in VS Code as a dev container.

| Container | What it is |
| --- | --- |
| `openvox-server` | OpenVox server and CA, `server.example.com` |
| `agent-alma` | AlmaLinux 10 target, `alma.example.com` |
| `agent-ubuntu` | Ubuntu 26.04 target, `ubuntu.example.com` |

The Codespace, or the dev container on your own machine, is the classroom host:
your editor, your terminal, and a private Docker daemon that the three
containers above run on.

## Getting started

### In a GitHub Codespace

1. Open <https://github.com/overlookinfra/classroom> on GitHub.
2. Click the green **Code** button, then the **Codespaces** tab.
3. Click the green button or the plus icon to create a codespace on `main`.

The codespace builds itself and starts the lab. Note that the VS Code window opens and may
show a terminal before it is actually done setting everything up. Eventually, it will show
a terminal while it runs the `postCreateCommand`. Wait for this to finish before checking
the status of the lab with `bin/status` in a new terminal window.

### Locally in VS Code

Open the folder and choose "Reopen in Container". That needs Docker and the Dev
Containers extension.

### First boot

Either way it takes a few minutes: the server generates a CA and the targets
download and install the agent. Check on it with:

```sh
bin/status
```

### Without a dev container

The compose file is self-contained and uses relative paths, so this works
directly on any Docker daemon:

```sh
docker compose -f .devcontainer/docker-compose.yml up -d
```

`bin/*` then drives whatever daemon your shell points at.

## The loop

Puppet code lives in `code/`, which is mounted into the server at
`/etc/puppetlabs/code`. Edit a manifest and apply it:

```sh
vim code/environments/production/manifests/site.pp
bin/alma puppet agent -t
```

There is no deploy step. Environment caching is turned off on the server, so
every run reads your code fresh off disk.

## Commands

```sh
bin/alma                            # shell into the AlmaLinux target
bin/ubuntu                          # shell into the Ubuntu target
bin/server                          # shell into the server
bin/server --root                   # shell into the server as root, for installing tools

bin/alma puppet agent -t            # run these without opening a shell
bin/server puppetserver ca list --all
bin/alma systemctl status httpd     # the targets run systemd, so services work

bin/status                          # container statuses, CA, agent certs
bin/agent-regen alma                # revoke and regenerate the agent's cert
```

## Choosing versions

The agent version is set by the `OPENVOX_AGENT_VERSION` environment variable in docker-compose.yml. By default,
this is an empty string and picks up the latest agent version.

If you already have the lab running and want to regenerate the agents to use a different version, after changing
`OPENVOX_AGENT_VERSION`, recreate the targets:

```sh
docker compose -f .devcontainer/docker-compose.yml up -d --force-recreate agent-alma agent-ubuntu
```

The server version is set via the server container image tag. By default, it picks up the latest server version,
but can be pinned to a particular version tag if desired.

## A note on autosigning

The server has `AUTOSIGN=true`, so it signs every certificate request it
receives without asking. That is only acceptable because **the CA is not
published anywhere**: port 8140 is reachable from the other containers on the
`classroom` bridge network, inside the dev container's own Docker daemon, and
from nowhere else, not even the machine running the dev container.

If you add a `ports:` entry for `openvox-server`, you put an autosigning CA on
the dev container's own network interface, where VS Code and Codespaces port
forwarding can carry it further. `bin/status` warns when it sees this. Change
`AUTOSIGN` to a certname whitelist file or an autosign policy script first;
`.devcontainer/docker-compose.yml` has the details.

## Layout

```
.devcontainer/
  devcontainer.json            Codespaces / VS Code entry point
  docker-compose.yml           The three lab containers and their versions
  scripts/                     Machinery, nothing in here is run by hand
    lab-up.sh                  Waits for the inner Docker daemon, compose up
    post-create.sh             Starts and configures the lab
    bootstrap-agent.sh         Installs the agent, generates a cert for it, starts systemd
bin/                           Commands for you to run
code/                          Puppet code mounted at /etc/puppetlabs/code in the server container
  environments/production/
    environment.conf
    manifests/site.pp
    modules/                   modules for this environment
  modules/                     modules shared across environments
```

## Caveats

The docker-in-docker feature runs this dev container privileged, which on your
own machine is root-equivalent. The lab, though, runs on a daemon inside the
dev container, so it cannot see or touch the containers and images on your machine.
Still, running docker-in-docker is not recommended on your local machine for security
reasons, so it's best to run this in GitHub Codespaces.

The two targets run systemd as PID 1 so that OpenVox can manage services on them,
which requires `privileged: true` on those containers. That is another reason to
prefer Codespaces over your own machine.

Lab state lives in a Docker volume the feature creates, named
`dind-var-lib-docker-*`, so images, containers, and with them the CA and the
signed certs survive a rebuild. Deleting the Codespace deletes all of it.
Locally the volume outlives the dev container, so `docker volume rm` on it is
what gives you a truly clean slate.
