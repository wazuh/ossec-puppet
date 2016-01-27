# Main ossec server config
class ossec::server (
  $mailserver_ip,
  $ossec_emailto,
  $ossec_emailfrom                     = "ossec@${::domain}",
  $ossec_active_response               = true,
  $ossec_rootcheck                     = true,
  $ossec_global_host_information_level = 8,
  $ossec_global_stat_level             = 8,
  $ossec_email_alert_level             = 7,
  $ossec_ignorepaths                   = [],
  $ossec_scanpaths                     = [ {'path' => '/etc,/usr/bin,/usr/sbin', 'report_changes' => 'no', 'realtime' => 'no'}, {'path' => '/bin,/sbin', 'report_changes' => 'yes', 'realtime' => 'yes'} ],
  $ossec_local_files                   = {},
  $ossec_emailnotification             = 'yes',
  $ossec_check_frequency               = 79200,
  $use_mysql                           = false,
  $manage_repos                        = true,
  $manage_epel_repo                    = true,
) inherits ossec::params {
  validate_bool(
    $ossec_active_response, $ossec_rootcheck,
    $use_mysql, $manage_repos, $manage_epel_repo
  )
  # This allows arrays of integers, sadly
  # (commented due to stdlib version requirement)
  #validate_integer($ossec_check_frequency, undef, 1800)
  validate_array($ossec_ignorepaths)

  if $::osfamily == 'windows' {
    fail('The ossec module does not yet support installing the OSSEC HIDS server on Windows')
  }

  if $manage_repos {
    # TODO: Allow filtering of EPEL requirement
    class { 'ossec::repo': redhat_manage_epel => $manage_epel_repo }
    Class['ossec::repo'] -> Package[$ossec::params::server_package]
  }

  if $use_mysql {
    # Relies on mysql module specified in metadata.json
    include mysql::client
    Class['mysql::client'] ~> Service[$ossec::params::server_service]
  }

  # install package
  package { $ossec::params::server_package:
    ensure  => installed
  }

  service { $ossec::params::server_service:
    ensure    => running,
    enable    => true,
    hasstatus => $ossec::params::service_has_status,
    pattern   => $ossec::params::server_service,
    require   => Package[$ossec::params::server_package],
  }

  # configure ossec
  concat { $ossec::params::config_file:
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    require => Package[$ossec::params::server_package],
    notify  => Service[$ossec::params::server_service]
  }
  concat::fragment { 'ossec.conf_10' :
    target  => $ossec::params::config_file,
    content => template('ossec/10_ossec.conf.erb'),
    order   => 10,
    notify  => Service[$ossec::params::server_service]
  }
  concat::fragment { 'ossec.conf_90' :
    target  => $ossec::params::config_file,
    content => template('ossec/90_ossec.conf.erb'),
    order   => 90,
    notify  => Service[$ossec::params::server_service]
  }

  concat { $ossec::params::keys_file:
    owner   => $ossec::params::keys_owner,
    group   => $ossec::params::keys_group,
    mode    => $ossec::params::keys_mode,
    notify  => Service[$ossec::params::server_service],
    require => Package[$ossec::params::server_package],
  }
  concat::fragment { 'var_ossec_etc_client.keys_end' :
    target  => $ossec::params::keys_file,
    order   => 99,
    content => "\n",
    notify  => Service[$ossec::params::server_service]
  }

  file { '/var/ossec/etc/shared/agent.conf':
    content => template('ossec/ossec_shared_agent.conf.erb'),
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    notify  => Service[$ossec::params::server_service],
    require => Package[$ossec::params::server_package]
  }

  Ossec::Agentkey<<| |>>

}
