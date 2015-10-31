# Define an ossec command
define ossec::command(
  $command_name,
  $command_executable,
  $command_expect = 'srcip',
  $timeout_allowed = true,
) {
  if ($timeout_allowed) { $command_timeout_allowed='yes' } else { $command_timeout_allowed='no' }
  concat::fragment { $name:
    target  => '/var/ossec/etc/ossec.conf',
    order   => 45,
    content => template('ossec/command.erb'),
  }
}
