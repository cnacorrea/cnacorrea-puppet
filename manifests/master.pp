class puppet::master (
  $puppetmaster_packages = [ 'puppet-server', 'ruby-devel', 'git' ],
  $puppetmaster_service  = 'puppetmaster',
  $modulepath            = '/puppet/modules-base:/puppet/modules-org',
  $hiera_config          = '/etc/hiera.yaml',
  $hiera_gems            = [ 'hiera-file', 'hiera-gpg' ],
  $rackdir               = '/etc/puppet/rack',
  $puppetdb_server       = undef,
) {
  package { $puppetmaster_packages:
    ensure => installed
  }

  package { $hiera_gems:
    provider => 'gem',
    ensure   => installed,
    require  => Package[$puppetmaster_packages],
  }

  puppet::config::add { 'modulepath':
    section => 'main',
    setting => 'modulepath',
    value   => "${modulepath}",
  }

  exec { 'create-ca-certificates':
    path    => '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
    command => 'puppet master --no-daemonize --verbose',
    creates => '/var/lib/puppet/ssl/ca/ca_crt.pem',
  }

  service { 'puppetmaster':
    name      => $puppetmaster_service,
    ensure    => stopped,
    enable    => false,
  }

  file { $rackdir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }

  file { "${rackdir}/public":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
    require => File[$rackdir],
  }

  file { "${rackdir}/tmp":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
    require => File[$rackdir],
  }

  file { 'cnacorrea-puppet-config.ru':
    path    => "$rackdir/config.ru",
    ensure  => 'present',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => 0644,
    content => template('puppet/config.ru.erb'),
    require => File["${rackdir}"],
  }

  class { 'apache':
  }

  class { 'apache::mod::passenger':
    passenger_high_performance   => 'on',
    passenger_max_pool_size      => '12',
    passenger_pool_idle_time     => '1500',
    passenger_stat_throttle_rate => '120',
    rack_autodetect              => 'Off',
    rails_autodetect             => 'Off',
  }

  apache::vhost { "${fqdn}":
    port              => '8140',
    docroot           => '/etc/puppet/rack/public/',
    ssl               => true,
    ssl_protocol      => '-ALL +SSLv3 +TLSv1',
    ssl_cipher        => 'ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP',
    ssl_cert          => "/var/lib/puppet/ssl/certs/${fqdn}.pem",
    ssl_key           => "/var/lib/puppet/ssl/private_keys/${fqdn}.pem",
    ssl_chain         => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ssl_ca            => '/var/lib/puppet/ssl/ca/ca_crt.pem',
    ssl_crl           => '/var/lib/puppet/ssl/ca/ca_crl.pem',
    ssl_verify_client => 'optional',
    ssl_verify_depth  => '1',
    ssl_options       => '+StdEnvVars +ExportCertData',
    request_headers   => [ 'set X-SSL-Subject %{SSL_CLIENT_S_DN}e',
                           'set X-Client-DN %{SSL_CLIENT_S_DN}e',
                           'set X-Client-Verify %{SSL_CLIENT_VERIFY}e' ],
    custom_fragment   => template('puppet/puppet-vhost-fragment.erb'),
    require           => [ File['cnacorrea-puppet-config.ru'],
                           Exec['create-ca-certificates'] ],
  }

  if ( $puppetdb_server == undef ) {
    puppet::config::del { 'storeconfigs':
      section => 'master',
      setting => 'storeconfigs',
    }

    puppet::config::del { 'storeconfigs_backend':
      section => 'master',
      setting => 'storeconfigs_backend',
    }
  } else {
    class { 'puppetdb::master::config':
      puppetdb_server => $puppetdb_server,
    }
  }
}
