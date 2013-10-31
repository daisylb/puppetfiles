# url: include protocol, leave out trailing slash
#
# After installing, you'll have to SSH into your server, and run:
#  su - sentryapp
#  . virtualenv/bin/activate
#  sentry --config=sentry.conf.py createsuperuser
#  sentry --config=sentry.conf.py repair --owner=<username>
class abre::sentry (
  $secret_key,
  $db_password,
  $url,
  $workers = 3,
  $email_host = localhost,
  $email_user = '',
  $email_pass = '',
  $email_port = 25,
  $email_tls = false,
){
  user {'sentryapp':
    ensure => present,
    home => '/home/sentryapp',
    managehome => true,
  }

  virtualenv::env {'/home/sentryapp/virtualenv':
    require => User['sentryapp'],
    user => 'sentryapp',
    group => 'sentryapp',
  }

  virtualenv::package {'sentryapp-sentry':
    package => 'sentry[postgres]',
    env => '/home/sentryapp/virtualenv',
  }

  postgresql::db {'sentryapp':
    user => 'sentry',
    password => $db_password,
  }

  file {'/home/sentryapp/sentry.conf.py':
    ensure => present,
    require => User['sentryapp'],
    content => template("abre/sentry.conf.py.erb"),
  }

  exec {'sentry-upgrade':
    command => "sentry --config=sentry.conf.py upgrade --noinput",
    user => 'sentryapp',
    group => 'sentryapp',
    cwd => '/home/sentryapp',
    require => [
      File['/home/sentryapp/sentry.conf.py'],
      Virtualenv::Package['sentryapp-sentry'],
      Postgresql::Db['sentryapp'],
    ],
    path =>
      '/home/sentryapp/virtualenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games',
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
      '/home/sentryapp/virtualenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games',
    },
  }

  nginx::resource::upstream {'sentry':
    ensure => present,
    members => "unix:/home/sentryapp/sentry.sock",
  }
}
