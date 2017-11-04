require 'spec_helper_acceptance'

#Note: ossec-agent from chocolatey.org is outdated. Use ossec-client for newer versions of ossec for windows

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

      apply_manifest(pp, :catch_failures => true)
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
