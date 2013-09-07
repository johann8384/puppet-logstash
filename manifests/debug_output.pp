class logstash::debug_output {
  ::logstash::config::output { ['output_stdout' ]:
    template        => 'stdout',
    plugin_tags     => [ "'local'" ],
    plugin_options  => [ "debug => true", "debug_format => 'json'" ],
  }
}
