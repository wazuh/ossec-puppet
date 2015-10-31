#Define for a specific ossec active-response
define ossec::activeresponse(
  $command_name,
  $ar_location = 'local',
  $ar_level    = 7,
  $ar_rules_id = [],
  $ar_timeout  = 300,
) {
  concat::fragment { $name:
    target  => '/var/ossec/etc/ossec.conf',
    order   => 55,
    content => template('ossec/activeresponse.erb')
  }
}
