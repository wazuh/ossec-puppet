#Define a log-file to add to ossec
define ossec::addlog_command(
  $logtype = 'syslog',
  $logcommand,
  $logfrequency = '60',
) {
  require ossec::params

  concat::fragment { "ossec.conf_20-${logfile}":
    target  => $ossec::params::config_file,
    content => template('ossec/20_ossecLogfile_command.conf.erb'),
    order   => 20,
    notify  => Service[$ossec::params::server_service]
  }

}
