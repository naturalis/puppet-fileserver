# == Class: fileserver
#
# Full description of class fileserver here.
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
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { fileserver:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
# Gebruikte modules
# https://forge.puppetlabs.com/puppetlabs/lvm
# https://github.com/ajjahn/puppet-samba
#
# voorbeeld op sdb en sdc
# $pvs = ['/dev/sdb', '/dev/sdc']
# $vg = 'vg1'
# $lv = 'lv1'
# $fstype = 'ext4'
# $sharedir = '/mnt/backup'
# 
# $disksize = $::blockdevice_sdb_size
# $nrdisks = size($pvs)

class fileserver( 
  $pvs,
  $vg             = 'vg1',
  $lv             = 'lv1',
  $fstype         = 'ext4',
  $sharedir       = '/mnt/backup',
  $nfs_allowed_ip = '',
){
  
  $pvs_array = split($pvs,',')
  
  physical_volume { $pvs_array:
  	ensure => present,
  } ->
  volume_group { $vg:
  	ensure           => present,
  	physical_volumes => $pvs_array,
  } ->
  exec { $lv:
  	command => "/sbin/lvcreate --name ${lv} ${vg} -l 100%FREE",
  	creates => "/dev/$vg/$lv",
  } ->
  filesystem { "/dev/${vg}/${lv}":
  	ensure  => present,
  	fs_type => $fstype,
  } ->

# Create and mount share directory
  file { $sharedir:
  	ensure => directory,
  	path   => $sharedir,
  } ->
  mount { 'sharemount':
  	ensure => 'mounted',
  	name   => $sharedir,
  	device => "/dev/${vg}/${lv}",
  	fstype => $fstype,
  	remounts => true,
  	options => "defaults",
  	atboot  => "true",
  } ->
  class {'samba::server':
 	workgroup => 'workgroup',
    server_string => "Samba Backup Server",
    interfaces => "eth0 lo",
    security => 'share'
  } ->
  samba::server::share {'backup-share':
  	comment => 'Backup Share',
  	path => $sharedir,
  	guest_only => true,
  	guest_ok => true,
  	guest_account => "guest",
  	browsable => false,
  	create_mask => 0777,
  	force_create_mask => 0777,
  	directory_mask => 0777,
  	force_directory_mask => 0777,
#  force_group => 'group',
#  force_user => 'user',
#  copy => 'some-other-share',
  }

  # Nfs mount point
  include concat::setup
  #include nfs::server
  nfs::server::export{$sharedir:
    clients => "${nfs_allowed_ip}(rw,sync,no_root_squash)",
    nfstag  => "${::hostname}_nfs_backup_share",
    require => File[$sharedir],
  }
}
