# OSSEC Puppet module

This module installs and configure OSSEC HIDS agent and manager.

## Documentation

* [Full documentation](http://documentation.wazuh.com)
* [OSSEC Puppet module documentation](https://documentation.wazuh.com/1.1/ossec_puppet.html)
* [Puppet Forge](https://forge.puppetlabs.com/wazuh/ossec)

## Credits and thank you

This Puppet module has been authored by Nicolas Zin, and updated by Jonathan Gazeley and Michael Porter. Wazuh has forked it with the purpose of maintaing it. Thank you to the authors for the contribution.

## Beaker Test

* add puppet environment variables for puppet_spec_helper

  ```
  $ export PUPPET_INSTALL_TYPE=agent
  $ export PUPPET_INSTALL_VERSION=1.9.3
  ```

* run default acceptance tests `$ bundle exec rake beaker`.
* run ubuntu agent test `BEAKER_setfile=spec/acceptance/nodesets/ubuntu-1404.yaml bundle exec rspec spec/acceptance/`.
* run centos agent test `BEAKER_setfile=spec/acceptance/nodesets/centos-72.yaml bundle exec rspec spec/acceptance`

## References

* [Wazuh website](http://wazuh.com)
* [OSSEC project website](http://ossec.github.io)
