# OpenVox Classroom Architecture

An ephemeral OpenVox lab: one server generating catalogs and running the CA,
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


## Starting the machine

1. Open <https://github.com/overlookinfra/classroom> on GitHub.
2. Click the green **Code** button, then the **Codespaces** tab.
3. Click the green button or the plus icon to create a codespace on `main`.

The codespace builds itself and starts the lab. Note that the VS Code window opens and may
show a terminal before it is actually done setting everything up. Eventually, it will show
a terminal while it runs the `postCreateCommand`. Wait for this to finish before checking
the status of the lab with `bin/status` in the terminal window. This may take several minutes.


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

bin/status                          # container statuses, CA, agent certs
bin/agent-regen alma                # revoke and regenerate the agent's cert
```

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


## Caveats

The docker-in-docker feature runs this dev container privileged, which on your
own machine is root-equivalent. The lab, though, runs on a daemon inside the
dev container, so it cannot see or touch the containers and images on your machine.
Still, running docker-in-docker is not recommended on your local machine for security
reasons, so it's best to run this in GitHub Codespaces.

Lab state lives in a Docker volume the feature creates, named
`dind-var-lib-docker-*`, so images, containers, and with them the CA and the
signed certs survive a rebuild. Deleting the Codespace deletes all of it.
Locally the volume outlives the dev container, so `docker volume rm` on it is
what gives you a truly clean slate.
