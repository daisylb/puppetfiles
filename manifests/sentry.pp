# url: include protocol, leave out trailing slash
class abre::sentry (
  $secret_key,
  $db_password,
  $url,
){
  user {'sentryapp':
    ensure => present,
    home => '/home/sentryapp',
    managehome => true,
  }

  virtualenv::env {'/home/sentryapp/virtualenv':
    require => User['sentryapp'],
  }

  virtualenv::package {'sentryapp-sentry':
    package => 'sentry[postgres]',
    env => '/home/sentryapp/virtualenv',
  }

  postgresql::db {'sentryapp':
    user => 'sentry',
    password => $db_password,
  }

  file {'/home/sentryapp/sentry.conf':
    ensure => present,
    require => User['sentryapp'],
  }

  exec {'sentry-upgrade':
    command => "sentry --config=sentry.conf.py upgrade --noinput",
    user => 'sentryapp',
    group => 'sentryapp',
    cwd => '/home/sentryapp',
    require => [
      File['/home/sentryapp/sentry.conf'],
      Virtualenv::Package['sentryapp-sentry'],
      Postgresql::Db['sentryapp'],
    ],
    environment => {
      'PATH' =>
      '/home/sentryapp/virtualenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:\
/usr/bin:/sbin:/bin:/usr/games',
    },
  }

  upstart::job {'sentryapp':
    ensure => present,
    respawn => true,
    exec => "sentry --config=sentry.conf.py start",
    user => 'sentryapp',
    chdir => '/home/sentryapp',
    require => [
      Exec['sentry-upgrade'],
    ],
    environment => {
      'PATH' =>
      '/home/sentryapp/virtualenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:\
/usr/bin:/sbin:/bin:/usr/games',
    },
  }
}
