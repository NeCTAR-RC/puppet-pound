class pound($logrotation='weekly') {

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
    order   => '01',
  }

  file {'/etc/default/pound':
    content => 'startup=1',
  }

  file {'/var/run/pound':
    ensure => directory,
  }

  logrotate::rule { 'pound':
    ensure  => present,
    path    => '/var/log/pound.log',
    options => [ 'rotate 52', $logrotation, 'missingok', 'notifempty', 'delaycompress', 'compress' ],
  }

}
