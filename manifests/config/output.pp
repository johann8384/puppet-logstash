define logstash::config::output($template, $plugin_tags = undef, $plugin_options = undef) {
  concat::fragment{"logstash_${name}":
    order   => 50,
    target  => "/etc/logstash/logstash.conf",
    content => template("logstash/etc/logstash.d/outputs/${template}.erb"),
  }
}
