# Define an email alert
define ossec::email_alert(
  $alert_email,
  $alert_group = false
) {
  concat::fragment { $name:
    target  => '/var/ossec/etc/ossec.conf',
    order   => 65,
    content => template('ossec/email_alert.erb'),
  }
}
