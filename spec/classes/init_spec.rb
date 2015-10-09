require 'spec_helper'
describe 'ossec' do

  context 'with defaults for all parameters' do
    it { should contain_class('ossec') }
  end
end
