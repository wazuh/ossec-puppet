# Define lightclient
class ossec::lightclient {
  @@concat::fragment { "ossec.conf_50_${::fqdn}" :
    target  => '/var/ossec/etc/ossec.conf',
    content => template('ossec/50_ossec.conf.erb'),
    order   => 50,
    notify  => Service[$ossec::common::hidsserverservice]
  }

  include rsyslog::client
}
