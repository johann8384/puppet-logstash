class logstash::config {
  concat::fragment{"logstash_input_start":
    order   => '00',
    target  => "/etc/logstash/logstash.conf",
    content => "input {\n"
  }

  concat::fragment{"logstash_input_end":
    order   => '19',
    target  => "/etc/logstash/logstash.conf",
    content => "}\n\n"
  }

  concat::fragment{"logstash_filter_start":
    order   => '20',
    target  => "/etc/logstash/logstash.conf",
    content => "filter {\n"
  }

  concat::fragment{"logstash_filter_end":
    order   => '39',
    target  => "/etc/logstash/logstash.conf",
    content => "}\n\n"
  }

  concat::fragment{"logstash_output_start":
    order   => '40',
    target  => "/etc/logstash/logstash.conf",
    content => "output {\n"
  }

  concat::fragment{"logstash_output_end":
    order   => '59',
    target  => "/etc/logstash/logstash.conf",
    content => "}\n\n"
  }

  concat{"/etc/logstash/logstash.conf":
    notify => Service['logstash'],
  }
}
