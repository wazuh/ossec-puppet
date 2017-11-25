require 'spec_helper_acceptance'

#Note: ossec-agent from chocolatey.org is outdated. Use ossec-client for newer versions of ossec for windows
if hosts.length > 1
  hosts_as('ossecwin28').each do |ossecwin28|

    describe 'ossec::client' do
      context 'ossec client 2.8 on windows' do
        it 'should install ossec::client for windows' do

        pp = <<-PP
          class { 'chocolatey': } ->
          chocolateyfeature {'allowEmptyChecksums':
            ensure => enabled,
          }->

          class { 'ossec::client':
            ossec_server_ip       => '10.10.11.10',
            ossec_server_hostname => 'ossecserver',
            agent_package_name    => 'ossec-agent',
            agent_package_version => '2.8',
            agent_source_url      => 'https://chocolatey.org/api/v2/',
            agent_name            => $::fqdn
          }

        PP

      result = apply_manifest_on(ossecwin28, pp, :catch_failures => true)
      expect(result.exit_code).to eq 2
    end

      describe package('OSSEC HIDS 2.8') do
        it { should be_installed }
      end

  end
  end
end

  hosts_as('ossecwin29').each do |ossecwin29|

    describe 'ossec::client' do
      context 'ossec client 2.9.2 on windows' do
        it 'should install ossec::client for windows' do

        pp = <<-PP
          class { 'chocolatey': } ->
          chocolateyfeature {'allowEmptyChecksums':
          ensure => enabled,
          }->

          class { 'ossec::client':
            ossec_server_ip       => '10.10.11.10',
            ossec_server_hostname => 'ossecserver',
            agent_package_name    => 'ossec-client',
            agent_package_version => '2.9.2',
            agent_source_url      => 'https://chocolatey.org/api/v2/',
            agent_name            => $::fqdn
          }

        PP

      result = apply_manifest_on(ossecwin29, pp, :catch_failures => true)
      expect(result.exit_code).to eq 2
    end

      describe package('OSSEC HIDS 2.9.2') do
        it { should be_installed }
      end

      describe service('OssecSvc') do
        it { should be_running }
        it { should be_enabled }
      end

  end
  end
end
end
