# Explore the resource abstraction layer

The OpenVox resource abstraction layer (RAL) is a useful tool which allows you
to treat various OS level resources nearly identically regardless of what the
resource is or what platform it's running on.

By this we mean that in the RAL, every resource is:

1. The type of resource,
2. Its name, and
3. A list of its attributes.

For example,

* a `file` of name `/etc/motd` with the attributes of `owner=root, group=root`
* a `package` of name `httpd` with the attribute of `version=2.4.68`
* a `service` of name `mysqld` with the attribute of `enabled=true`

## Exercises

After your Codespace environment is finished starting up, use some of the RAL
commands below to explore different resources on your nodes.

* `bin/alma puppet resource file /etc/motd`
* `bin/ubuntu puppet resource file /etc/motd`

Observe that the Alma image has an `/etc/motd` file and the content is represented as a
hash rather than the actual file contents. The Ubuntu image however has no `/etc/motd`,
and so it's reported as `ensure=>absent`.

Try similar commands with other resource types. For example, try `puppet resource user root`.

You will likely not know which resource types exist. Ask OpenVox to tell you what
it knows about by running `puppet resource --types` on one of your nodes. Obviously
they're not all applicable to Alma and Ubuntu, so ask for an explanation of what
some of them manage. For example, try `puppet describe package` and see that not only
does it explain what the type does and what attributes it supports, but it tells you
what platforms it can run on.

Finally, experiment with *changing* a resource with

* `bin/ubuntu puppet resource file /etc/motd content="Hello from DevopsDaysPDX"`
* `bin/ubuntu cat /etc/motd`
* Alma Linux is missing some package used by OpenVox. Let's resolve that now:
    * `bin/alma puppet resource package util-linux ensure=present`
    * `bin/alma puppet resource package procps ensure=present`

> [!CAUTION]
> It might be fun to see how much you can poke at your nodes, but we have extremely
> limited time for troubleshooting, so please don't try to break them.
>
> You can. It's not hard, you have `root` access. But we won't have time to help you get them running again.
