require 'beaker-rspec'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'winrm'

GEOTRUST_GLOBAL_CA = <<-EOM.freeze
  -----BEGIN CERTIFICATE-----
  MIIDVDCCAjygAwIBAgIDAjRWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT
  MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i
  YWwgQ0EwHhcNMDIwNTIxMDQwMDAwWhcNMjIwNTIxMDQwMDAwWjBCMQswCQYDVQQG
  EwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEbMBkGA1UEAxMSR2VvVHJ1c3Qg
  R2xvYmFsIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2swYYzD9
  9BcjGlZ+W988bDjkcbd4kdS8odhM+KhDtgPpTSEHCIjaWC9mOSm9BXiLnTjoBbdq
  fnGk5sRgprDvgOSJKA+eJdbtg/OtppHHmMlCGDUUna2YRpIuT8rxh0PBFpVXLVDv
  iS2Aelet8u5fa9IAjbkU+BQVNdnARqN7csiRv8lVK83Qlz6cJmTM386DGXHKTubU
  1XupGc1V3sjs0l44U+VcT4wt/lAjNvxm5suOpDkZALeVAjmRCw7+OC7RHQWa9k0+
  bw8HHa8sHo9gOeL6NlMTOdReJivbPagUvTLrGAMoUgRx5aszPeE4uwc2hGKceeoW
  MPRfwCvocWvk+QIDAQABo1MwUTAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTA
  ephojYn7qwVkDBF9qn1luMrMTjAfBgNVHSMEGDAWgBTAephojYn7qwVkDBF9qn1l
  uMrMTjANBgkqhkiG9w0BAQUFAAOCAQEANeMpauUvXVSOKVCUn5kaFOSPeCpilKIn
  Z57QzxpeR+nBsqTP3UEaBU6bS+5Kb1VSsyShNwrrZHYqLizz/Tt1kL/6cdjHPTfS
  tQWVYrmm3ok9Nns4d0iXrKYgjy6myQzCsplFAMfOEVEiIuCl6rYVSAlk6l5PdPcF
  PseKUgzbFbS9bZvlxrFUaKnjaZC2mqUPuLk/IH2uSrW4nOQdtqvmlKXBx4Ot2/Un
  hw4EbNX/3aBd7YdStysVAq45pmp06drE57xNNB6pXE0zX5IJL4hmXXeXxx12E6nV
  5fEWCRE11azbJHFwLJhWC9kXtNHjUStedejV0NxPNO3CBWaAocvmMw==
  -----END CERTIFICATE-----
EOM
# Install Puppet on all hosts

run_puppet_install_helper

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|

      if host.name == 'ossecserver'
        install_dev_puppet_module_on(host, :source => module_root, :module_name => 'ossec',
          :target_module_path => '/etc/puppetlabs/code/environments/production/modules')
        on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
        on(host, puppet('module', 'install', 'puppetlabs-concat'))
        on(host, puppet('module', 'install', 'puppetlabs-apt'))
        on(host, puppet('module', 'install', 'puppetlabs-mysql'))
        on(host, puppet('module', 'install', 'puppet-selinux'))

        pp = <<-EOS
          class { 'ossec::server':
            mailserver_ip           => '127.0.0.1',
            ossec_emailto           => ['nobody@nowhere.com'],
            manage_repos            => true,
            ossec_emailnotification => 'no',
            syslog_output           => false,
          }
        EOS

        apply_manifest_on(host, pp, :catch_failures => false)
      elsif host.name =~ /ossecagent-win*/
        install_cert_on_windows(host, 'geotrustglobal', GEOTRUST_GLOBAL_CA)
        install_dev_puppet_module_on(host, :source => module_root, :module_name => 'ossec',
          :target_module_path => 'C:\ProgramData\PuppetLabs\code\environments\production\modules')
        on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
        on(host, puppet('module', 'install', 'puppetlabs-concat')) 
        on(host, puppet('module', 'install', 'puppetlabs-registry'))
        on(host, puppet('module', 'install', 'puppetlabs-powershell'))
        on(host, puppet('module', 'install', 'puppetlabs-chocolatey'))
        on(host, puppet('module', 'install', 'puppet-download_file'))
      else
        install_dev_puppet_module_on(host, :source => module_root, :module_name => 'ossec',
          :target_module_path => '/etc/puppetlabs/code/environments/production/modules')
        on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
        on(host, puppet('module', 'install', 'puppetlabs-concat'))
        on(host, puppet('module', 'install', 'puppetlabs-apt'))
        on(host, puppet('module', 'install', 'puppet-selinux'))
        on(host, puppet('module', 'install', 'stahnma-epel'))
      end
    end
  end
end
