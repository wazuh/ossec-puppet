# utility function to fill up /var/ossec/etc/client.keys
define ossec::agentkey(
  $agent_id,
  $agent_name,
  $agent_ip_address,
  $agent_seed = 'xaeS7ahf',
) {
  if $agent_id {
    $agentKey1 = ossec_md5("${agent_id} ${agent_seed}")
    $agentKey2 = ossec_md5("${agent_name} ${agent_ip_address} ${agent_seed}")

    concat::fragment { "var_ossec_etc_client.keys_${agent_name}_part":
      target  => '/var/ossec/etc/client.keys',
      order   => $agent_id,
      content => "${agent_id} ${agent_name} ${agent_ip_address} ${agentKey1}${agentKey2}\n",
    }
  } else {
    notify{ "ossec::agentkey: ${agent_id} is missing": }
  }
}

