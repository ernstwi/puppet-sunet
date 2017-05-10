class sunet::exabgp::monitor (
  String  $path       = '/etc/bgp/monitor.d',
  Integer $sleep_time = 2
) {
   file { '/etc/bgp/monitor.d': ensure => directory } ->
   file { '/etc/bgp/monitor':
      ensure   => file,
      mode     => '0755',
      content  => template("sunet/exabgp/monitor.erb")
   }
}

define sunet::exabgp::monitor::url(
  String           $url,
  String           $route,
  Optional[String] $match = undef,   # string to look for on the URL
  Integer          $prio  = 10,
  String           $path  = '/etc/bgp/monitor.d',
) {
   require stdlib
   $check_url = $url ? {
      undef   => $name,
      default => $url
   }
   ensure_resource('class','Sunet::Exabgp::Monitor', { path => $path, })
   $safe_title = regsubst($name, '[^0-9A-Za-z.\-]', '-', 'G')
   file {"${path}/${prio}_${safe_title}":
      ensure   => file,
      content  => template('sunet/exabgp/monitor/url.erb'),
      mode     => '0755'
   }
}

define sunet::exabgp::monitor::haproxy(
  Integer $index,
  Array   $ipv4,
  Array   $ipv6,
  String  $path      = '/etc/bgp/monitor.d',
  String  $scriptdir = '/opt/frontend/haproxy/scripts',
  String  $hookdir   = '/opt/frontend/haproxy/hooks',
) {
  require stdlib
  $site = $name
  ensure_resource('class','Sunet::Exabgp::Monitor', { path => $path, })
  $safe_title = regsubst($site, '[^0-9A-Za-z.\-]', '-', 'G')
  file {
    "${path}/${prio}_${safe_title}":
      ensure   => file,
      content  => template('sunet/exabgp/monitor/haproxy.erb'),
      mode     => '0755'
      ;
  }

  $ipv4str = join($ipv4, ',')
  $ipv6str = join($ipv6, ',')
  exec { "haproxy_hook_${site}_UP":
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
    command => "$scriptdir/haproxy-hook-maker --up 'site=${site}; index=${index}; ipv4=$ipv4str; ipv6=$ipv6str' > $hookdir/${site}_UP.sh",
    creates => "$hookdir/${site}_UP.sh",
  }

  exec { "haproxy_hook_${site}_DOWN":
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
    command => "$scriptdir/haproxy-hook-maker --down 'site=${site}; index=${index}; ipv4=$ipv4str; ipv6=$ipv6str' > $hookdir/${site}_DOWN.sh",
    creates => "$hookdir/${site}_DOWN.sh",
  }

  file { ["$hookdir/${site}_UP.sh", "$hookdir/${site}_DOWN.sh"]:
      mode => '0755',
  }
}
