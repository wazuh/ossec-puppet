require 'spec_helper_acceptance'


apply_manifests_opts = {
  :catch_failures => true,
  :modulepath     => 'C:\ProgramData\PuppetLabs\code\environments\production\modules',
  :debug          => true
}

describe 'ossec::client' do  
  context 'ossec client on windows' do
    it 'should install ossec::client for windows' do

      pp = <<-PP
        class { 'chocolatey': } ->
        chocolateyfeature {'allowEmptyChecksums':
         ensure => enabled,
        }

      PP

      apply_manifest(pp, apply_manifests_opts)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to eql 0
    end

    #describe package('OSSEC HIDS 2.8') do
    #  it { should be_installed }
    #end

    #describe service('OssecSvc') do
    #  it { should be_running }
    #  it { should be_enabled }
    #end

  end
end  
