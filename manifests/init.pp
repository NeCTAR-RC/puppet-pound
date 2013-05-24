class pound {

  include concat::setup
  $pound_cfg = '/etc/pound/pound.cfg'

  package {'pound':
    ensure => installed,
  }

  service {'pound':
    ensure  => running,
    require => Package['pound'],
  }

  concat {$pound_cfg:
    owner  => root,
    group  => root,
    mode   => '0644',
    notify => Service['pound'],
  }

  concat::fragment {'01-header':
    target  => $pound_cfg,
    content => template('pound/pound.cfg.erb'),
    order   => 01,
  }

  file {'/etc/default/pound':
    content => 'startup=1',
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

    concat::fragment {"vhost-$name":
      target  => $pound::pound_cfg,
      content => template('pound/vhost.cfg.erb'),
      order   => 10,
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
