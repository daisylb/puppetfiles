class abre::django {
  include nginx
  include postgresql::server
  include virtualenv
  include upstart
  package {['git', 'libpq-dev', 'python-dev', 'libxml2-dev', 'libxslt-dev']:
    ensure => present,
  }
}
