require 'spec_helper_acceptance'


#apply_manifests_opts = {
#  :catch_failures => true,
#  :modulepath     => 'C:\ProgramData\PuppetLabs\code\environments\production\modules',
#  :debug          => true
#}
  describe 'ossec::client' do  
    context 'ossec client on windows' do
      it 'should install ossec::client for windows' do

        pp = <<-PP
          class { 'chocolatey': } ->
          chocolateyfeature {'allowEmptyChecksums':
          ensure => enabled,
          }->

          class { 'ossec::client':
            ossec_server_ip       => '10.10.11.10',
            ossec_server_hostname => 'ossecserver',
            agent_package_version => 'latest',
            agent_source_url      => 'https://chocolatey.org/api/v2/',
            agent_name            => $::fqdn 
          }

        PP

      apply_manifest(pp, :catch_failures => true)
      #expect(apply_manifest(pp, :catch_failures => true).exit_code).to eql 0
    end

    describe package('OSSEC HIDS 2.8') do
      it { should be_installed }
    end

    describe service('OssecSvc') do
      it { should be_running }
      it { should be_enabled }
    end

  end
end
