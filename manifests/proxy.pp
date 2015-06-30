# Proxy defined type
define proxy($port, $backend_port, $ssl=true, $backend_ip=false, $backends=undef, $emergency_ip=false, $emergency_port=false, $nagios_check=true) {

  include pound

  if $backend_ip {
    $backends_real = [$backend_ip,]
  } else {
    $backends_real = $backends
  }
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
