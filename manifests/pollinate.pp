define sunet::pollinate($device = "/dev/random") {
   package {"pollinate": ensure => latest } ->
   file { "/etc/default/pollinate": 
      ensure => file,
      owner  => root,
      group  => root,
      content => template("sunet/pollen/pollinate.erb")
   } ->
   cron {"repollinate": 
      command => "pollinate -r",
      user    => root,
      hour    => "*",
      minute  => "0"
   }
}
