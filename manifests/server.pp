class logstash::server inherits ::logstash::base {
  include ::logstash::config

  $elasticsearch_host   = $::logstash::base::elasticsearch_host
  $elasticsearch_port   = $::logstash::base::elasticsearch_port
  $firewall_accept_port = $::logstash::base::firewall_accept_port
  $syslog_accept_port   = $::logstash::base::syslog_accept_port
  $applog_accept_port   = $::logstash::base::applog_accept_port

  ::logstash::config::input { ['input_tcp' ]:
    template        => 'tcp',
    plugin_tags     => [ "'remote'" ],
    plugin_type     => 'json-events',
    plugin_options  => [ "port => ${applog_accept_port}", "mode => 'server'", "format => 'json_event'" ],
  }

  ::logstash::config::input { ['input_udp' ]:
    template        => 'udp',
    plugin_tags     => [ "'remote'" ],
    plugin_type     => 'json-events',
    plugin_options  => [ "port => ${applog_accept_port}", "format => 'json_event'" ],
  }

  ::logstash::config::filter { ['filter_json_events' ]:
    template        => 'json_events',
    plugin_type     => 'json-events',
  }

  ::logstash::config::output { ['output_elasticsearch_http' ]:
    template        => 'elasticsearch-http',
    plugin_options  => [ "host => '${elasticsearch_host}'", "port => ${elasticsearch_port}", "exclude_tags => [ '_phpparsefailure', '_grokparsefailure' ]" ],
  }

#ouch, this did bad things to the cluster....please don't enable it
#  ::logstash::config::output { ['output_elasticsearch' ]:
#    template        => 'elasticsearch',
#    plugin_options  => [ "cluster => 'es_cluster_${datacenter}'", "embedded => false", "host => '${elasticsearch_host}'", "port => 9300" ],
#  }
}
