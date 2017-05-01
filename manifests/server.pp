# Main ossec server config
class ossec::server (
  $mailserver_ip,
  $ossec_emailto,
  $ossec_emailfrom                     = "ossec@${::domain}",
  $ossec_active_response               = true,
  $ossec_rootcheck                     = true,
  $ossec_rootcheck_frequency           = 36000,
  $ossec_rootcheck_checkports          = true,
  $ossec_rootcheck_checkfiles          = true,
  $ossec_global_host_information_level = 8,
  $ossec_global_stat_level             = 8,
  $ossec_email_alert_level             = 7,
  $ossec_ignorepaths                   = [],
  $ossec_scanpaths                     = [ {'path' => '/etc,/usr/bin,/usr/sbin', 'report_changes' => 'no', 'realtime' => 'no'}, {'path' => '/bin,/sbin', 'report_changes' => 'yes', 'realtime' => 'yes'} ],
  $ossec_white_list                    = [],
  $ossec_extra_rules_config            = [],
  $ossec_extra_rules_folder_config     = [],
  $ossec_local_files                   = $::ossec::params::default_local_files,
  $ossec_emailnotification             = 'yes',
  $ossec_email_maxperhour              = '12',
  $ossec_email_idsname                 = undef,
  $ossec_check_frequency               = 79200,
  $ossec_auto_ignore                   = 'yes',
  $ossec_prefilter                     = false,
  $ossec_service_provider              = $::ossec::params::ossec_service_provider,
  $ossec_server_port                   = '1514',
  $use_db                              = false,
  $db_type                             = undef,
  $db_hostname                         = undef,
  $db_name                             = undef,
  $db_password                         = undef,
  $db_username                         = undef,
  $server_package_version              = 'installed',
  $manage_repos                        = true,
  $manage_epel_repo                    = true,
  $manage_client_keys                  = true,
  $syslog_output                       = false,
  $syslog_output_server                = undef,
  $syslog_output_format                = undef,
  $local_decoder_template              = 'ossec/local_decoder.xml.erb',
  $local_rules_template                = 'ossec/local_rules.xml.erb',
  $shared_agent_template               = 'ossec/ossec_shared_agent.conf.erb',
  $ossec_conf_template                 = 'ossec/10_ossec.conf.erb',
) inherits ossec::params {
  validate_bool(
    $ossec_active_response, $ossec_rootcheck,
    $use_db, $manage_repos, $manage_epel_repo, $syslog_output
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

  # install package
  package { $ossec::params::server_package:
    ensure  => $server_package_version
  }

  service { $ossec::params::server_service:
    ensure    => running,
    enable    => true,
    hasstatus => $ossec::params::service_has_status,
    pattern   => $ossec::params::server_service,
    provider  => $ossec_service_provider,
    require   => Package[$ossec::params::server_package],
  }

  # configure ossec process list
  concat { $ossec::params::processlist_file:
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    require => Package[$ossec::params::server_package],
    notify  => Service[$ossec::params::server_service]
  }
  concat::fragment { 'ossec_process_list_10' :
    target  => $ossec::params::processlist_file,
    content => template('ossec/10_process_list.erb'),
    order   => 10,
    notify  => Service[$ossec::params::server_service]
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
    content => template($ossec_conf_template),
    order   => 10,
    notify  => Service[$ossec::params::server_service]
  }

  if $use_db {
    validate_string($db_type)
    validate_string($db_hostname)
    validate_string($db_name)
    validate_string($db_password)
    validate_string($db_username)

    case $db_type {
      'mariadb': {
        class { 'mysql::client': package_name => 'mariadb-client' }
        Class['mysql::client'] ~> Service[$ossec::params::server_service]
      }
      'mysql': {
        include mysql::client
        Class['mysql::client'] ~> Service[$ossec::params::server_service]
      }
      'postgresql': {
        include postgresql::client
        Class['postgresql::client'] ~> Service[$ossec::params::server_service]
      }
      default: {
        fail('$db_type must either be mysql, maridb or postgresl')
      }
    }

    # Enable the database in the config
    concat::fragment { 'ossec.conf_80' :
      target  => $ossec::params::config_file,
      content => template('ossec/80_ossec.conf.erb'),
      order   => 80,
      notify  => Service[$ossec::params::server_service]
    }

    # Enable the database daemon in the .process_list
    concat::fragment { 'ossec_process_list_20' :
      target  => $ossec::params::processlist_file,
      content => template('ossec/20_process_list.erb'),
      order   => 20,
      notify  => Service[$ossec::params::server_service]
    }
  }

  concat::fragment { 'ossec.conf_90' :
    target  => $ossec::params::config_file,
    content => template('ossec/90_ossec.conf.erb'),
    order   => 90,
    notify  => Service[$ossec::params::server_service]
  }

  if ( $manage_client_keys == true ) {
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
  }

  file { '/var/ossec/etc/shared/agent.conf':
    content => template($shared_agent_template),
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    notify  => Service[$ossec::params::server_service],
    require => Package[$ossec::params::server_package]
  }

  file { '/var/ossec/rules/local_rules.xml':
    content => template($local_rules_template),
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    notify  => Service[$ossec::params::server_service],
    require => Package[$ossec::params::server_package]
  }

  file { '/var/ossec/etc/local_decoder.xml':
    content => template($local_decoder_template),
    owner   => $ossec::params::config_owner,
    group   => $ossec::params::config_group,
    mode    => $ossec::params::config_mode,
    notify  => Service[$ossec::params::server_service],
    require => Package[$ossec::params::server_package]
  }

  if ( $manage_client_keys == true ) {
    # A separate module to avoid storeconfigs warnings when not managing keys
    include ossec::collect_agent_keys
  }
}
