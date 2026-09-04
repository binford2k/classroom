# Designing a profile class

A profile class pulls together component modules, primarily sourced from
the Puppet Forge, and configures them into a single stack the way it's
used in a single site. It exposes only the parameters allowing the
variations supported by that specific site.

Now that we have the required modules to run an Apache website installed, let's
put together a quick profile for it. Profile classes can be found in the
`profile` module's `manifests` directory, and local modules like `role` and
`profile` are found in each environment's `site` directory.

## Exercise

1. Find and edit the `profile::apache` profile class.
    * `/code/environments/production/site/profile/manifests/apache.pp`
2. We'd like a little more control over the configuration, so disable the default
   vhost and uncomment the code required to define our own version.
3. [Advanced]: We'd like to add a second vhost running on port 443 with SSL
   enabled. What code changes can you guess might enable that?

