# Find modules on the Forge

The Puppet Forge is the source for community modules. Many of these
modules are published and maintained by [Vox Pupuli](https://voxpupuli.org).
For confusing historical reasons, their Forge namespace is [`puppet`](https://forge.puppet.com/modules/puppet)
while that of Puppet by Perforce is [`puppetlabs`](https://forge.puppet.com/modules/puppetlabs).

## Exercises:

1. Visit the Forge and explore; search for modules to manage various technologies.
    * Open https://forge.puppet.com
    * Search for:
        * Apache or Nginx
        * LetsEncrypt
        * Atlassian
        * SELinux
2. Deploy modules to manage an Apache stack
    * Edit `/code/environments/production/Puppetfile`
    * Find the commented out section listing the required modules.
    * Uncomment by removing the hash marks from each `mod` line.
    * Run the command `bin/deploy` and ensure no errors are output.
3. Validate the installation with
    * `bin/server ls /etc/puppetlabs/code/environments/production/modules/`
    * Ensure that each module from the `Puppetfile` is listed.
