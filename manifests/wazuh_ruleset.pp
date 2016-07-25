# Puppetize the instructions on http://documentation.wazuh.com/en/latest/ossec_ruleset.html#automatic-installation
class ossec::wazuh_ruleset {

  file { '/var/cache/wget':
    ensure => directory
  } ->
  file { '/var/ossec/update':
    ensure => directory
  } ->
  file { '/var/ossec/update/rulesets':
    ensure => directory
  } ->
  wget::fetch { 'https://raw.githubusercontent.com/wazuh/ossec-rules/stable/ossec_ruleset.py':
    destination => '/var/ossec/update/rulesets/',
    cache_dir   => '/var/cache/wget',
    mode        => '0755',
    verbose     => false,
    notify      => Exec['get ossec_ruleset']
  }

  exec { 'get ossec_ruleset':
    command     => '/var/ossec/update/rulesets/ossec_ruleset.py -s',
    cwd         => '/var/ossec/update/rulesets/',
    refreshonly => true
  }

  cron { 'cron_update_rules':
    command => 'cd /var/ossec/update/rulesets && ./ossec_ruleset.py -s',
    user    => 'root',
    weekday => '6',
    hour    => '3',
    minute  => '23'
  }
}



