# Puppetize the instructions on http://documentation.wazuh.com/en/latest/ossec_ruleset.html#automatic-installation
class ossec::wazuh_ruleset {

  file { '/var/cache/wget':
    ensure => directory
  } ->
  file { '/var/ossec/update':
    ensure => directory
  } ->
  file { '/var/ossec/update/ruleset':
    ensure => directory
  } ->
  wget::fetch { 'https://raw.githubusercontent.com/wazuh/ossec-rules/stable/ossec_ruleset.py':
    destination => '/var/ossec/update/ruleset/',
    cache_dir   => '/var/cache/wget',
    mode        => '0755',
    verbose     => false,
    notify      => Exec['get ossec_ruleset']
  }

  exec { 'get ossec_ruleset':
    command     => '/var/ossec/update/ruleset/ossec_ruleset.py -s',
    cwd         => '/var/ossec/update/ruleset/',
    refreshonly => true
  }
}
