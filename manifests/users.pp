# == Class: fileserver::users
#
#Installs users from hiera.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { fileserver::users: }
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
# === Copyright
#
# Copyright 2013 Naturalis, unless otherwise noted.
#
define fileserver::users(
  $username = $title,
  $password,
) {
  
  user { $username:
    ensure      => present,
  } ->
  exec { $username:
    command 	=> "echo -e \"${password}\\n${password}\\n\" | /usr/bin/pdbedit -a -t --user=${username}",
    path 	=> "/usr/local/bin/:/bin/:/usr/bin",
    require 	=> Class['samba::server'],
    unless      => "/usr/bin/pdbedit -L | grep -c ${username}:"

  }
}
