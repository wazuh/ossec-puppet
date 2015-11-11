# Setup for ossec client
class ossec::client(
  $ossec_active_response   = true,
  $ossec_rootcheck         = true,
  $ossec_server_ip,
  $ossec_emailnotification = 'yes',
  $ossec_ignorepaths       = [],
  $ossec_local_files       = {},
  $ossec_check_frequency   = 79200,
  $selinux                 = false,
) inherits ossec::params {
  validate_bool(
    $ossec_active_response, $ossec_rootcheck,
    $selinux
  )
  # This allows arrays of integers, sadly
  # (commented due to stdlib version requirement)
  #validate_integer($ossec_check_frequency, undef, 1800)
  validate_array($ossec_ignorepaths)


  case $::kernel {
    'Linux' : {
      include ossec::repo
      Class['ossec::repo'] -> Package[$ossec::params::agent_package]
      package { $ossec::params::agent_package:
        ensure  => installed
      }
    }
    'windows' : {
          
          file {
          'C:/ossec-win32-agent-2.8.3.exe':
          owner              => 'Administrators',
          group              => 'Administrators',
          mode               => '0774',
          source             => 'puppet:///modules/ossec/ossec-win32-agent-2.8.3.exe',
          source_permissions => ignore
	 }

      package { $ossec::params::agent_package:
        ensure          => installed,
        source          => 'C:/ossec-win32-agent-2.8.3.exe',
        install_options => [ '/S' ],  # Nullsoft installer silent installation
        require         => File['C:/ossec-win32-agent-2.8.3.exe'],
     }
    }
    default: { fail('OS not supported') }
  }

  service { $ossec::params::agent_service:
    ensure    => running,
    enable    => true,
    hasstatus => $ossec::params::service_has_status,
    pattern   => $ossec::params::agent_service,
    require   => Package[$ossec::params::agent_package],
  }

  concat { $ossec::params::config_file:
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    require => Package[$ossec::params::agent_package],
    notify  => Service[$ossec::params::agent_service],
 }
  concat::fragment { 'ossec.conf_10' :
    target  => $ossec::params::config_file,
    content => template('ossec/10_ossec_agent.conf.erb'),
    order   => 10,
    notify  => Service[$ossec::params::agent_service]
  }
  concat::fragment { 'ossec.conf_99' :
    target  => $ossec::params::config_file,
    content => template('ossec/99_ossec_agent.conf.erb'),
    order   => 99,
    notify  => Service[$ossec::params::agent_service]
  }

  concat { $ossec::params::keys_file:
    owner   => $ossec::params::keys_owner,
    group   => $ossec::params::keys_group,
    mode    => $ossec::params::keys_mode,
    notify  => Service[$ossec::params::agent_service],
    require => Package[$ossec::params::agent_package]
  }
  ossec::agentkey{ "ossec_agent_${::fqdn}_client":
    agent_id         => fqdn_rand(3000),
    agent_name       => $::hostname,
    agent_ip_address => $::ipaddress,
  }
  @@ossec::agentkey{ "ossec_agent_${::fqdn}_server":
    agent_id         => fqdn_rand(3000),
    agent_name       => $::hostname,
    agent_ip_address => $::ipaddress
  }

  if ($::kernel == 'Linux') {
    # Set log permissions properly to fix
    # https://github.com/djjudas21/puppet-ossec/issues/20
    file { '/var/ossec/logs':
      ensure  => directory,
      require => Package[$ossec::params::agent_package],
      owner   => 'ossec',
      group   => 'ossec',
      mode    => '0755',
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
}
