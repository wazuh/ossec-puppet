require 'spec_helper_acceptance'

#Note: ossec-agent from chocolatey.org is outdated. Use ossec-client for newer versions of ossec for windows
if hosts.length > 1

  hosts_as('ossecubuntu').each do |ossecubuntu|

   describe 'ossec::client' do
     context 'ossec client 2.8 on linux' do
       it 'should install ossec::client for linux' do

        pp = <<-PP
          class { 'ossec::client':
            ossec_server_ip       => '10.10.11.10',
            ossec_server_hostname => 'ossecserver',
            agent_name            => $::fqdn
          }

        PP

       result = apply_manifest_on(ossecubuntu, pp, :catch_failures => true)
       expect(result.exit_code).to eq 2
    end

    if fact('osfamily') == 'Debian'

      describe package('ossec-hids-agent') do
        it { should be_installed }
      end

      describe service('ossec') do
        it { should be_running }
        it { should be_enabled }
      end
    end

   end
  end
  end
end
