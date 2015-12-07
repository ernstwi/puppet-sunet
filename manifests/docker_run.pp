# Common use of docker::run
define sunet::docker_run(
  $image,
  $imagetag            = hiera('sunet_docker_default_tag', 'latest'),
  $volumes             = [],
  $ports               = [],
  $expose              = [],
  $env                 = [],
  $net                 = 'bridge',
  $extra_parameters    = [],
  $command             = "",
  $hostname            = undef,
  $start_on            = $docker::params::service_name,
  $stop_on             = $docker::params::service_name
) {
  include docker::params
  # Make container use unbound resolver on dockerhost
  # If docker was just installed, facter will not know the IP of docker0. Thus the pick.
  $dns = $net ? {
    'host'  => [],  # docker refuses --dns with --net host
    default => [pick($::ipaddress_docker0, '172.17.42.1')],
  }

  $image_tag = "${image}:${imagetag}"
  docker::image { "${name}_${image_tag}" :  # make it possible to use the same docker image more than once on a node
    image              => $image_tag,
    require            => [Package['docker-engine'],
                           ],
  } ->

  docker::run { $name :
    use_name           => true,
    image              => $image_tag,
    volumes            => flatten([$volumes,
                           '/etc/passwd:/etc/passwd:ro',  # uid consistency
                           '/etc/group:/etc/group:ro',    # gid consistency
                           ]),
    hostname           => $hostname,
    ports              => $ports,
    expose             => $expose,
    env                => $env,
    net                => $net,
    extra_parameters   => flatten([$extra_parameters,
                                   '--rm',
                                   ]),
    dns                => $dns,
    verify_checksum    => false,    # Rely on registry security for now. eduID risk #31.
    command            => $command,
    pre_start          => 'run-parts /usr/local/etc/docker.d',
    post_start         => 'run-parts /usr/local/etc/docker.d',
    pre_stop           => 'run-parts /usr/local/etc/docker.d',
    start_on           => $start_on,
    stop_on            => $stop_on,
  }

}
