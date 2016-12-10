# Puppetize the instructions on http://documentation.wazuh.com/en/latest/ossec_ruleset.html#automatic-installation
class ossec::wazuh_ruleset_cron {

  require ossec::wazuh_ruleset

  cron { 'cron_update_rules':
    command => 'cd /var/ossec/update/ruleset && ./ossec_ruleset.py -s',
    user    => 'root',
    weekday => '6',
    hour    => '3',
    minute  => '23'
  }
}
