#Define a log-file to add to ossec
define ossec::addlog(
  $logfile,
  $logtype = 'syslog',
) {
  require ossec::params

  concat::fragment { "ossec.conf_20-${logfile}":
    target  => $ossec::params::config_file,
    content => template('ossec/20_ossecLogfile.conf.erb'),
    order   => 20,
    notify  => Service[$ossec::params::server_service]
  }

}
