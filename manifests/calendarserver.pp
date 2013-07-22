class abre::calendarserver {
  package {'calendarserver':
    ensure => present,
  }
  file {'/etc/default/calendarserver':
    ensure => present,
    content => "start_calendarserver=yes\n",
  }
  nginx::resource::upstream {'calendarserver':
    ensure => present,
    members => ['127.0.0.1:8008'],
  }
}
