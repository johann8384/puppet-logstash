define logstash::config::input($template, $plugin_type, $plugin_tags = undef, $plugin_options = undef) {
  concat::fragment{"logstash_${name}":
    order   => 10,
    target  => "/etc/logstash/logstash.conf",
    content => template("logstash/etc/logstash.d/inputs/${template}.erb"),
  }
}
