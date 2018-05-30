require 'spec_helper'

describe 'ossec::server' do
  on_supported_os.each do |os, facts|
    if not os =~ /windows/
      context "on #{os}" do
        let (:facts) do
          facts.merge({ :concat_basedir => '/dummy' })
        end
        context 'with defaults for all parameters' do
          let(:params) do
            {
              :ossec_emailto => ['root@localhost.localdomain'],
            }
          end
          it do
            expect { is_expected.to compile.with_all_deps }.to raise_error(/Must pass mailserver_ip/)
          end
        end
        context 'with valid paramaters' do
          let (:params) do
            {
              :mailserver_ip => '127.0.0.1',
              :ossec_emailto => ['root@localhost.localdomain'],
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('ossec::server') }
        end
      end
    end
  end
end
