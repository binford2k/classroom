# Profile Parameters in Hiera

The ability to customize configuration via parameters specified
on a hierarchical rules basis is one of the major strengths of
the OpenVox ecosystem. You can define layers based on the
operating system, infrastructure role, or anything else that
you can write a fact for.

There are primarily two sources of keys we can use when defining these
rules. Facts are information known about the node. We'll cover them in
the Language Basics section. There's also a subset of facts that are
verified and encoded into the node's SSL certificate so they cannot
be modified.

## Exercises

1. First let's see what kind of information we can use to define our hierarchy.
    * `bin/alma facter networking.fqdn`
    * `bin/ubuntu facter networking.hostname`
    * `bin/alma facter os`
    * `bin/ubuntu facter os`
2. Take a look at the hierarchy definition and see if you can predict where data files will go.
    * `/code/environments/production/hiera.yaml`
3. Explore the `data` directory of the `production` environment and see if your predictions were correct.
    * `/code/environments/production/data`
4. Edit the OS family layer's data file for Debian and change the `content` key.
    * `/code/environments/production/data/os/Debian.yaml`
    * Which of your two agent nodes will be affected? Why?
5. Create a per-node override for your Alma Linux node.
    * Run `bin/alma puppet config print certname` to see the value to use.
    * Create the appropriately named yaml file in `/code/environments/production/data/nodes`

> [!TIP]
> Notice that the parameters you provide in Hiera override the defaults specified in code.
