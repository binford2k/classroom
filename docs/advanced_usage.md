# Advanced usage

## Running locally in VS Code

Open the folder and choose "Reopen in Container". That needs Docker and the Dev
Containers extension.


## Without a dev container

The compose file is self-contained and uses relative paths, so this works
directly on any Docker daemon:

```sh
docker compose -f .devcontainer/docker-compose.yml up -d
```

`bin/*` then drives whatever daemon your shell points at.


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
