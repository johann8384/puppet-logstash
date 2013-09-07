class logstash::frontend inherits ::logstash::base {
  include ::logstash::config

  $elasticsearch_host   = $::logstash::base::elasticsearch_host
  $elasticsearch_port   = $::logstash::base::elasticsearch_port
  $logstash_host        = $::logstash::base::logstash_host
  $firewall_accept_port = $::logstash::base::firewall_accept_port
  $syslog_accept_port   = $::logstash::base::syslog_accept_port
  $applog_accept_port   = $::logstash::base::applog_accept_port

  ::logstash::config::input { ['input_json_file' ]:
    template        => 'file',
    plugin_tags     => [ "'local'" ],
    plugin_type     => 'custom-json-encoded',
    plugin_options  => [ "path => [ '/var/log/application/hdfs_logs_json_*/hdfs_logs_json_*.log' ]", "format => 'plain'", "start_position => 'beginning'" ],
  }

  ::logstash::config::input { ['input_splunk_log' ]:
    template        => 'file',
    plugin_tags     => [ "'local'", "'splunk'" ],
    plugin_type     => 'splunk-format',
    plugin_options  => [ "path => [ '/var/log/application/splunk/*/*.log', '/var/log/application/oris2splunk/oris2splunk.log' ]", "format => 'plain'", "start_position => 'beginning'" ],
  }

  ::logstash::config::input { ['input_all_files' ]:
    template        => 'file',
    plugin_tags     => [ "'local'", "'raw-file-search'" ],
    plugin_type     => 'raw-file-search',
    plugin_options  => [ "path => [ '/var/log/apache/access_log', '/var/log/nginx/access_log', '/var/log/nginx/error.log', '/var/log/apache/modsec_audit.log', '/var/log/apache/performance_log', '/var/log/apache/error_log' ]", "format  => 'plain'", "start_position => 'beginning'" ],
  }

  ::logstash::config::filter { ['filter_custom-json-encoded' ]:
    template        => 'custom-json-encoded',
    plugin_type     => 'custom-json-encoded',
  }

  ::logstash::config::filter { ['filter_splunk_log' ]:
    template        => 'url-encoded',
    plugin_type     => 'splunk-format',
  }

  ::logstash::config::filter { ['filter_raw_file_search' ]:
    template        => 'raw-file-search',
    plugin_type     => 'raw-file-search',
  }

  ::logstash::config::output { ['output_elasticsearch_http' ]:
    template        => 'elasticsearch-http',
    plugin_tags     => [ "'local'", "'raw-file-search-matched'" ],
    plugin_options  => [ "host => '${elasticsearch_host}'", "port => ${elasticsearch_port}", "exclude_tags => [ 'raw-file-search-missed', '_phpparsefailure', '_grokparsefailure', 'webapp' ]" ],
  }

  ::logstash::config::output { ['output_http_webapp' ]:
    template        => 'http',
    plugin_tags     => [ "'webapp'" ],
    plugin_options  => [ "http_method => 'post'", "url => 'http://localhost/internal/consume_download_info_from_nginx'", "exclude_tags => ['raw-file-search', 'splunk']", 'mapping => ["timestamp", "%{@timestamp}", "source_host", "%{@source_host}", "message", "%{@message}"]' ],
  }
}
