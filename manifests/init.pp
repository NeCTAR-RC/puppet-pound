class pound($vhosts) {
  
  package {'pound':
    ensure => installed,
  }

  service {'pound':
    ensure  => running,
    require => Package['pound'],
  }

  file {'/etc/pound/pound.cfg':
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('pound/pound.cfg.erb'),
    notify  => Service['pound'],
  }

  file {'/var/run/pound':
    ensure => directory,
  }

  file {'/etc/pound/sites-enabled':
    ensure  => directory,
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['pound'],
    require => Package['pound'],
  }

  
  define proxy($port, $ssl=true, $backend_ip, $backend_port, $nagios_check=true) {
    include pound
    
    if $ssl {
      $listen_protocol = 'ListenHTTPS'
      
      File <| tag == 'sslcert' |> {
        notify +> Service['pound'],
      }
      
    }
    else {
      $listen_protocol = 'ListenHTTP'
    }

    file {"/etc/pound/sites-enabled/${name}.cfg":
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('pound/vhost.cfg.erb'),
      notify  => Service['pound'],
    }
    
    if $nagios_check {
      if $ssl {
        nagios::service { "http_${port}":
          check_command => "https_port!${port}";
        }
      }
      else {
        nagios::service { "http_${port}":
          check_command => "http_port!${port}";
        }
      }
    }
  }
}
