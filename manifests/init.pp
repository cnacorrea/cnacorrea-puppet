# == Class: puppet
#
# Full description of class puppet here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { puppet:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class puppet(
  $puppet_packages           = [ 'puppet' ],
  $puppet_service            = 'puppet',
  $logdir                    = '/var/log/puppet',
  $rundir                    = '/var/run/puppet',
  $ssldir                    = '$vardir/ssl',
  $ssl_client_header         = 'SSL_CLIENT_S_DN',
  $ssl_client_verify_header  = 'SSL_CLIENT_VERIFY',
  $classfile                 = '$vardir/classes.txt',
  $localconfig               = '$vardir/localconfig',
  $pluginsync                = 'true',
) {
  package { $puppet_packages:
    ensure => installed
  }

  class { 'puppet::config':
    logdir                   => "${logdir}",
    rundir                   => "${rundir}",
    ssldir                   => "${ssldir}",
    ssl_client_header        => "${ssl_client_header}",
    ssl_client_verify_header => "${ssl_client_verify_header}",
    classfile                => "${classfile}",
    localconfig              => "${localconfig}",
    pluginsync               => "${pluginsync}",
    require                  => Package[$puppet_packages],
  }

  service { 'puppet':
    name      => $puppet_service,
    ensure    => running,
    enable    => true,
    subscribe => Class['puppet::config'],
    require   => Class['puppet::config'],
  }
}

define puppet::config::add(
  $section = '',
  $setting = '#',
  $value   = '',
) {
  ini_setting { "cnacorrea-puppet-${title}":
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => $section,
    setting => $setting,
    value   => $value,
  }
}

define puppet::config::del(
  $section = '',
  $setting = '#',
) {
  ini_setting { "cnacorrea-puppet-${title}":
    ensure  => absent,
    path    => '/etc/puppet/puppet.conf',
    section => $section,
    setting => $setting,
  }
}

class puppet::config(
  $logdir                    = '/var/log/puppet',
  $rundir                    = '/var/run/puppet',
  $ssldir                    = '$vardir/ssl',
  $ssl_client_header         = 'SSL_CLIENT_S_DN',
  $ssl_client_verify_header  = 'SSL_CLIENT_VERIFY',
  $classfile                 = '$vardir/classes.txt',
  $localconfig               = '$vardir/localconfig',
  $pluginsync                = 'true',
) {
  puppet::config::add { 'logdir':
    section => 'main',
    setting => 'logdir',
    value   => "${logdir}",
  }

  puppet::config::add { 'rundir':
    section => 'main',
    setting => 'rundir',
    value   => "${rundir}",
  }

  puppet::config::add { 'ssldir':
    section => 'main',
    setting => 'ssldir',
    value   => "${ssldir}",
  }

  puppet::config::add { 'ssl_client_header':
    section => 'main',
    setting => 'ssl_client_header',
    value   => "${ssl_client_header}",
  }

  puppet::config::add { 'ssl_client_verify_header':
    section => 'main',
    setting => 'ssl_client_verify_header',
    value   => "${ssl_client_verify_header}",
  }

  puppet::config::add { 'classfile':
    section => 'agent',
    setting => 'classfile',
    value   => "${classfile}",
  }

  puppet::config::add { 'localconfig':
    section => 'agent',
    setting => 'localconfig',
    value   => "${localconfig}",
  }

  puppet::config::add { 'pluginsync':
    section => 'agent',
    setting => 'pluginsync',
    value   => "${pluginsync}",
  }
}
