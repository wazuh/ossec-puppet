# Package installation
class ossec::common {
  case $::osfamily {
    'Debian' : {
      $hidsagentservice  = 'ossec'
      $hidsagentpackage  = 'ossec-hids-agent'
      $servicehasstatus  = false

      case $::lsbdistcodename {
        /(lucid|precise|trusty)/: {
          $hidsserverservice = 'ossec'
          $hidsserverpackage = 'ossec-hids'

          apt::source { 'wazuh':
            ensure              => present,
            comment             => 'This is the WAZUH Ubuntu repository for Ossec',
            location    => 'http://ossec.wazuh.com/repos/apt/ubuntu',
            release             => $::lsbdistcodename,
            repos               => 'main',
            key         => {
              id                => '9FE55537D1713CA519DFB85114B9C8DB9A1B1C65',
              source            => 'http://ossec.wazuh.com/repos/apt/conf/ossec-key.gpg.key',
            },
          }
          ~>
          exec { 'update-apt-wazuh-repo':
            command     => '/usr/bin/apt-get update',
            refreshonly => true
        }
        }
        /^(jessie|wheezy)$/: {
          $hidsserverservice = 'ossec'
          $hidsserverpackage = 'ossec-hids'

          apt::source { 'wazuh':
            ensure      => present,
            comment     => 'This is the WAZUH Debian repository for Ossec',
            location    => 'http://ossec.wazuh.com/repos/apt/debian',
            release     => $::lsbdistcodename,
            repos       => 'main',
            include_src => false,
            include_deb => true,
            key         => '9A1B1C65',
            key_source  => 'http://ossec.wazuh.com/repos/apt/conf/ossec-key.gpg.key',
          }
          ~>
          exec { 'update-apt-wuzh':
            command     => '/usr/bin/apt-get update',
            refreshonly => true
          }
        }
        default: { fail('This ossec module has not been tested on your distribution (or lsb package not installed)') }
      }
    }
    'Redhat' : {
      # Set up OSSEC rpm gpg key
      file { 'RPM-GPG-KEY.ossec.txt':
        path   => '/etc/pki/rpm-gpg/RPM-GPG-KEY.ossec.txt',
        source => 'puppet:///modules/ossec/RPM-GPG-KEY.ossec.txt',
        owner  => 'root',
        group  => 'root',
        mode   => '0664',
      }

      # Set up OSSEC repo
      yumrepo { 'wazuh':
        descr      => 'WAZUH OSSEC Repository - www.wazuh.com',
        enabled    => true,
        gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY.ossec.txt',
        baseurl    => 'http://ossec.wazuh.com/el/$releasever/$basearch',
        priority   => 1,
        protect    => false,
        require    => [ File['RPM-GPG-KEY.ossec.txt'], Class['epel'] ]
      }

      # Set up EPEL repo
      include epel

      $hidsagentservice  = 'ossec-hids-agent'
      $hidsagentpackage  = 'ossec-hids-agent'
      $hidsserverservice = 'ossec-hids'
      $hidsserverpackage = 'ossec-hids'
      $servicehasstatus  = true
      case $::operatingsystemrelease {
        /^5/:    {$redhatversion='el5'}
        /^6/:    {$redhatversion='el6'}
        /^7/:    {$redhatversion='el7'}
        default: { }
      }
      package { 'inotify-tools':
        ensure  => present,
        require => Class['epel'],
      }
    }
    default: { fail('This ossec module has not been tested on your distribution') }
  }
}
