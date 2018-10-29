# Paramas file
class ossec::params {
  case $::kernel {
    'Linux': {

      $config_file = '/var/ossec/etc/ossec.conf'
      $config_mode = '0440'
      $config_owner = 'root'
      $config_group = 'ossec'

      $keys_file = '/var/ossec/etc/client.keys'
      $keys_mode = '0440'
      $keys_owner = 'root'
      $keys_group = 'ossec'

      $processlist_file = '/var/ossec/bin/.process_list'
      $processlist_mode = '0440'
      $processlist_owner = 'root'
      $processlist_group = 'ossec'

      $rootkit_files = '/var/ossec/etc/shared/rootkit_files.txt'
      $rootkit_trojans = '/var/ossec/etc/shared/rootkit_trojans.txt'

      $manage_firewall = false

      case $::osfamily {
        'Debian': {

          $agent_service            = 'ossec'
          $agent_package            = 'ossec-hids-agent'
          $service_has_status       = false
          $agent_source_url         = undef
          $agent_chocolatey_enabled = undef
          $agent_download_url       = undef
          $ossec_service_provider   = undef

          $default_local_files = {
            '/var/log/syslog'             => 'syslog',
            '/var/log/auth.log'           => 'syslog',
            '/var/log/mail.log'           => 'syslog',
            '/var/log/dpkg.log'           => 'syslog',
            '/var/log/apache2/access.log' => 'apache',
            '/var/log/apache2/error.log'  => 'apache'
          }

          case $::lsbdistcodename {
            /(precise|trusty|vivid|wily|xenial)/: {
              $server_service = 'ossec'
              $server_package = 'ossec-hids'
            }
            /^(jessie|wheezy|stretch|sid)$/: {
              $server_service = 'ossec'
              $server_package = 'ossec-hids'
            }
            default: { fail('This ossec module has not been tested on your distribution (or lsb package not installed)') }
          }
        }
        'Linux', 'RedHat': {

          $agent_service            = 'ossec-hids-agent'
          $agent_package            = 'ossec-hids-agent'
          $server_service           = 'ossec-hids'
          $server_package           = 'ossec-hids'
          $agent_source_url         = undef
          $agent_chocolatey_enabled = undef
          $agent_download_url       = undef
          $service_has_status       = true
          $ossec_service_provider   = 'redhat'

          $default_local_files = {
            '/var/log/messages'         => 'syslog',
            '/var/log/secure'           => 'syslog',
            '/var/log/maillog'          => 'syslog',
            '/var/log/yum.log'          => 'syslog',
            '/var/log/httpd/access_log' => 'apache',
            '/var/log/httpd/error_log'  => 'apache'
          }

        }
        default: { fail('This ossec module has not been tested on your distribution (or lsb package not installed)') }
      }
    }
    'windows': {
      $config_file = regsubst(sprintf('c:/Program Files (x86)/ossec-agent/ossec.conf'), '\\\\', '/')
      $config_owner = 'Administrator'
      $config_group = 'Administrators'
      $manage_firewall = false

      $keys_file  = regsubst(sprintf('c:/Program Files (x86)/ossec-agent/client.keys'), '\\\\', '/')
      $keys_mode  = '0440'
      $keys_owner = 'Administrator'
      $keys_group = 'Administrators'

      $agent_service = 'OssecSvc'
      $agent_package = 'ossec-agent'

      $agent_source_url         = 'https://chocolatey.org/api/v2/'
      $agent_chocolatey_enabled = false
      $agent_download_url       = 'http://ossec.wazuh.com/windows'

      $server_service = ''
      $server_package = ''
      $service_has_status  = true

      $rootkit_files = ''
      $rootkit_trojans = ''

      # Pushed by shared agent config now
      $default_local_files = {}

    }
    'FreeBSD' : {
      $config_file = '/usr/local/ossec-hids/etc/ossec.conf'
      $config_mode = '0440'
      $config_owner = 'root'
      $config_group = 'ossec'

      $keys_file = '/usr/local/ossec-hids/etc/client.keys'
      $keys_mode = '0440'
      $keys_owner = 'root'
      $keys_group = 'ossec'

      $processlist_file = '/usr/local/ossec-hids/bin/.process_list'
      $processlist_mode = '0440'
      $processlist_owner = 'root'
      $processlist_group = 'ossec'
      $agent_service  = 'ossec-hids'
      $agent_package  = 'ossec-hids-client'
      $server_service = 'ossec-hids'
      $server_package = 'ossec-hids-server'
      $agent_source_url = undef
      $agent_chocolatey_enabled = undef
      $agent_download_url = undef
      $service_has_status = true
      $ossec_service_provider = 'freebsd'
      $default_local_files = {
        '/var/log/auth.log' => 'syslog',
        '/var/log/security' => 'syslog',
      }
    }
    default: { fail('This ossec module has not been tested on your distribution') }
  }
}
