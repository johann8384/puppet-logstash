class logstash::base {
  $elasticsearch_host   = $::base::variables::elasticsearch_host
  $logstash_host        = $::base::variables::logstash_host
  $elasticsearch_port   = $::base::variables::elasticsearch_port
  $firewall_accept_port = $::base::variables::logstash_port_firewall
  $syslog_accept_port   = $::base::variables::logstash_port_syslog
  $applog_accept_port   = $::base::variables::logstash_port_applog

  $service_enable = true
  $service_ensure = running

  package { 'logstash':
    ensure => latest,
    notify => Service['logstash'],
  }

  file { '/var/lib/logstash':
    ensure  => directory,
    require => [ Package['logstash'], Package['daemon'] ],
    mode    => 0770,
  }

  file { '/usr/lib/logstash':
    ensure  => directory,
    require => [ Package['logstash'], Package['daemon'] ],
    mode    => 0555,
  }

  file { '/usr/lib/logstash/filters':
    ensure  => absent,
    force   => true,
    recurse => true,
  }

  file { '/usr/sbin/logstash':
    source  => 'puppet:///logstash/usr/sbin/logstash',
    require => [ Package['logstash'], Package['daemon']],
    notify  => Service['logstash'],
    mode    => 0555,
  }

  file { '/etc/init.d/logstash':
    source  => 'puppet:///logstash/etc/init.d/logstash',
    require => [ Package['logstash'], Package['daemon'] ],
    notify  => Service['logstash'],
    mode    => 0550,
  }

  ::logrotate::file { 'logstash':
    logrotatefile => '/etc/logrotate.logstash.conf',
    logfile   => '/var/log/logstash.*',
    options   => ['size 250M','rotate 5','missingok','compress','delaycompress','dateext'],
  }

  cron { 'rotate_logstash_files':
      ensure  => 'present',
      command => '/usr/sbin/logrotate /etc/logrotate.logstash.conf > /dev/null 2>&1',
      minute  => '10',
      hour    => '*',
  }

  file { '/usr/share/logstash/logstash/filters/urlhandler.rb':
    source  => 'puppet:///logstash/usr/share/logstash/logstash/filters/urlhandler.rb',
    require => Package['logstash'],
    notify  => Service['logstash'],
    mode    => 0550,
  }

  file { '/usr/share/logstash/logstash/filters/php.rb':
    source  => 'puppet:///logstash/usr/share/logstash/logstash/filters/php.rb',
    require => Package['logstash'],
    notify  => Service['logstash'],
    mode    => 0550,
  }

  file { '/usr/share/logstash/logstash/filters/json.rb':
    source  => 'puppet:///logstash/usr/share/logstash/logstash/filters/json.rb',
    require => Package['logstash'],
    notify  => Service['logstash'],
    mode    => 0550,
  }

  service { 'logstash':
    enable     => $service_enabled,
    ensure     => $service_ensure,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => [ File['/etc/init.d/logstash'], Package['logstash'] ],
    require    => [ Package['logstash'], File['/etc/init.d/logstash'], File['/usr/lib/logstash'] ],
  }
}
