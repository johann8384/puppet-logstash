define logstash::config::filter($template, $plugin_type, $plugin_tags = undef, $plugin_options = undef) {
  concat::fragment{"logstash_${name}":
    order   => 30,
    target  => "/etc/logstash/logstash.conf",
    content => template("logstash/etc/logstash.d/filters/${template}.erb"),
  }
}
