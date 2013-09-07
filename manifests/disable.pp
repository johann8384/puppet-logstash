class logstash::disable {
   # Sometimes we fix things on the init script, so ensure package and init script are current

  package { 'logstash':
    ensure => latest,
  }

  file { '/etc/init.d/logstash':
    source  => 'puppet:///logstash/etc/init.d/logstash',
    require => [ Package['logstash'], Package['daemon'] ],
    notify  => Service['logstash'],
    mode    => 0664,
  }

  service { 'logstash':
    enable     => false,
    ensure     => stopped,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File['/etc/init.d/logstash'],
    require    => [ Package['logstash'], File['/etc/init.d/logstash'] ],
  }
}
