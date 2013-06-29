# = Definition: git::repo
#
# == Parameters:
#
# $target::   Target folder. Required.
#
# $bare::     Create a bare repository. Defaults to false.
#
# $source::   Source to clone from. If not specified, no remote will be used.
#
# $user::     Owner of the repository. Defaults to root.
#
# == Usage:
#
#   git::repo {'mygit':
#     target => '/home/user/puppet-git',
#     source => 'git://github.com/theforeman/puppet-git.git',
#     user   => 'user',
#   }
#
define git::repo (
  $target,
  $bare    = false,
  $source  = false,
  $user    = 'root',
  $update  = false,
  $branch  = 'master',
) {

  require git::params

  if $source {
    $cmd = "${git::params::bin} clone ${source} ${target} --recursive"
  } else {
    if $bare {
      $cmd = "${git::params::bin} init --bare ${target}"
    } else {
      $cmd = "${git::params::bin} init ${target}"
    }
  }

  $creates = $bare ? {
    true  => "${target}/objects",
    false => "${target}/.git",
  }

  exec { "git_repo_for_${name}":
    command => $cmd,
    creates => $creates,
    require => Class['git::install'],
    user    => $user
  }

  if ! $bare {
    exec { "git_repo_branch_for_${name}":
      command => "${git::params::bin} checkout ${branch}",
      unless  => "${git::params::bin} branch | grep -P '\\* ${branch}'",
      require => Exec["git_repo_for_${name}"],
    }
  }

  if $update {
    exec { "git_update_repo_for_${name}":
      user    => $user,
      command => "${git::params::bin} reset --hard origin/${branch}",
      unless  => "${git::params::bin} fetch && ${git::params::bin} diff origin/${branch} --no-color --exit-code",
      require => Exec["git_repo_for_${name}"],
    }
  }
}
