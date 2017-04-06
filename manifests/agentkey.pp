# utility function to fill up /var/ossec/etc/client.keys
define ossec::agentkey(
  $agent_id,
  $agent_name,
  $agent_ip_address,
  $agent_seed = 'xaeS7ahf',
) {
  require ::ossec::params

  if ! $agent_id { fail("ossec::agentkey: ${agent_id} is missing")}

  $agentkey1 = md5("${agent_id} ${agent_seed}")
  $agentkey2 = md5("${agent_name} ${agent_ip_address} ${agent_seed}")

  concat::fragment { "var_ossec_etc_client.keys_${agent_name}_part":
    target  => $ossec::params::keys_file,
    order   => $agent_id,
    content => "${agent_id} ${agent_name} ${agent_ip_address} ${agentkey1}${agentkey2}\n",
  }

}
