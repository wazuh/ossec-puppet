# Setup for ossec client
class ossec::client(
Boolean          $ossec_active_response      = true,
Boolean          $ossec_rootcheck            = true,
String           $ossec_server_ip            = '',
String           $ossec_server_hostname      = '',
String           $ossec_server_port          = '1514',
Array            $ossec_scanpaths            = [],
Enum['yes','no'] $ossec_emailnotification    = 'yes',
Array            $ossec_ignorepaths          = [],
Hash             $ossec_local_files          = $::ossec::params::default_local_files,
String           $ossec_config_owner         = $::ossec::params::config_owner,
String           $ossec_config_group         = $::ossec::params::config_group,
String           $ossec_keys_owner           = $::ossec::params::keys_owner,
String           $ossec_keys_group           = $::ossec::params::keys_group,
Integer          $ossec_check_frequency      = 79200,
Boolean          $ossec_prefilter            = false,
String           $ossec_service_provider     = $::ossec::params::ossec_service_provider,
Boolean          $selinux                    = false,
String           $agent_name                 = $::hostname,
String           $agent_ip_address           = $::ipaddress,
Boolean          $manage_repo                = true,
Boolean          $manage_epel_repo           = true,
String           $agent_source_url           = $::ossec::params::agent_source_url,
String           $agent_package_name         = $::ossec::params::agent_package,
Boolean          $agent_chocolatey_enabled   = $::ossec::params::agent_chocolatey_enabled,
String           $agent_download_url         = $::ossec::params::agent_download_url,
String           $agent_download_directory   = 'C:\Temp',
String           $agent_package_version      = 'installed',
String           $agent_service_name         = $::ossec::params::agent_service,
Boolean          $manage_client_keys         = true,
Integer          $max_clients                = 3000,
String           $ar_repeated_offenders      = '',
Boolean          $service_has_status         = $::ossec::params::service_has_status,
Integer          $ossec_rootcheck_frequency  = 36000,
Boolean          $ossec_rootcheck_checkports = true,
Boolean          $ossec_rootcheck_checkfiles = true,
String           $rootkit_files              = $::ossec::params::rootkit_files,
String           $rootkit_trojans            = $::ossec::params::rootkit_trojans,
Enum['yes','no'] $ossec_alert_new_files      = 'yes',
Array            $ossec_ignorepaths_regex    = [],
Boolean          $manage_firewall            = $::ossec::params::manage_firewall,
String           $ossec_conf_template        = 'ossec/10_ossec_agent.conf.erb',

) inherits ossec::params {

  if ( ( $ossec_server_ip == '' ) and ( $ossec_server_hostname == '' ) ) {
    fail('must pass either $ossec_server_ip or $ossec_server_hostname to Class[\'ossec::client\'].')
  }

  case $::kernel {
    'Linux' : {
      if $manage_repo {
      class { 'ossec::repo': redhat_manage_epel => $manage_epel_repo }
      Class['ossec::repo'] -> Package[$agent_package_name]
        package { $agent_package_name:
          ensure  => $agent_package_version
      }

      } else {
      package { $agent_package_name:
        ensure => $agent_package_version
      }
      }
    }
    'windows' : {

    if $agent_chocolatey_enabled {
      include chocolatey
      package { $agent_package_name:
        ensure   => $agent_package_version,
        source   => $agent_source_url,
        provider => 'chocolatey',
      }
    }else{
      file { $agent_download_directory:
        ensure => directory,
      }

      archive::download { "${agent_download_directory}\\${agent_package_name}-win32-${agent_package_version}.exe" :
        url      => "${agent_download_url}/${agent_package_name}-win32-${agent_package_version}.exe",
        checksum => false
      }
      package { $agent_package_name:
        ensure          => $agent_package_version,
        source          => "${agent_download_directory}\\${agent_package_name}-win32-${agent_package_version}.exe",
        install_options => [ '/S' ],  # Nullsoft installer silent installation
        require         => Archive::Download["${agent_download_directory}\\${agent_package_name}-win32-${agent_package_version}.exe"]
      }
    }
    }
    'FreeBSD' : {
        package { $agent_package_name:
            ensure => $agent_package_version
        }
    }
    default: { fail('OS not supported') }
  }

  service { $agent_service_name:
    ensure    => running,
    enable    => true,
    hasstatus => $service_has_status,
    pattern   => $agent_service_name,
    provider  => $ossec_service_provider,
    require   => Package[$agent_package_name],
  }

  concat { $ossec::params::config_file:
    owner   => $ossec_config_owner,
    group   => $ossec_config_group,
    mode    => $ossec::params::config_mode,
    require => Package[$agent_package_name],
    notify  => Service[$agent_service_name],
  }

  concat::fragment { 'ossec.conf_10' :
    target  => $ossec::params::config_file,
    content => template($ossec_conf_template),
    order   => 10,
    notify  => Service[$agent_service_name]
  }

  if ( $ar_repeated_offenders != '' and $ossec_active_response == true ) {
    concat::fragment { 'repeated_offenders' :
      target  => $ossec::params::config_file,
      content => template('ossec/ar_repeated_offenders.erb'),
      order   => 55,
      notify  => Service[$agent_service_name]
    }
  }

  concat::fragment { 'ossec.conf_99' :
    target  => $ossec::params::config_file,
    content => template('ossec/99_ossec_agent.conf.erb'),
    order   => 99,
    notify  => Service[$agent_service_name]
  }

  if ( $manage_client_keys == true ) {
    concat { $ossec::params::keys_file:
      owner   => $ossec_keys_owner,
      group   => $ossec_keys_group,
      mode    => $ossec::params::keys_mode,
      notify  => Service[$agent_service_name],
      require => Package[$agent_package_name]
    }
    # A separate module to avoid storeconfigs warnings when not managing keys
    class { 'ossec::export_agent_key':
      max_clients      => $max_clients,
      agent_name       => $agent_name,
      agent_ip_address => $agent_ip_address,
    }
  } elsif ($::kernel == 'Linux') {
    # Is this really Linux only?
    $ossec_server_address = pick($ossec_server_ip, $ossec_server_hostname)
    exec { 'agent-auth':
      command => "/var/ossec/bin/agent-auth -m ${ossec_server_address} -A ${::fqdn} -D /var/ossec/",
      creates => '/var/ossec/etc/client.keys',
      require => Package[$agent_package_name],
    }
  }

  if ($::kernel == 'Linux') {
    # Set log permissions properly to fix
    # https://github.com/djjudas21/puppet-ossec/issues/20
    file { '/var/ossec/logs':
      ensure  => directory,
      require => Package[$agent_package_name],
      owner   => 'ossec',
      group   => 'ossec',
      mode    => '0750',
    }

    # SELinux
    # Requires selinux module specified in metadata.json
    if ($::osfamily == 'RedHat' and $selinux == true) {
      selinux::module { 'ossec-logrotate':
        ensure => 'present',
        source => 'puppet:///modules/ossec/ossec-logrotate.te',
      }
    }
  }
  # Manage firewall
  if $manage_firewall {
    include firewall
    firewall { '1514 ossec-agent':
      dport  => $ossec_server_port,
      proto  => 'udp',
      action => 'accept',
      state  => [
        'NEW',
        'RELATED',
        'ESTABLISHED'],
    }
  }
}

