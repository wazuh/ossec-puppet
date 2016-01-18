require 'spec_helper'
describe 'ossec::client' do

  context 'with defaults for all parameters' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('ossec::client') }
  end
end
