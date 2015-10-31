#Define a log-file to add to ossec
define ossec::addlog(
  $logfile,
  $logtype = 'syslog',
) {
  concat::fragment { "ossec.conf_20-${logfile}":
    target  => '/var/ossec/etc/ossec.conf',
    content => template('ossec/20_ossecLogfile.conf.erb'),
    order   => 20,
    notify  => Service[$ossec::common::hidsserverservice]
  }

}
