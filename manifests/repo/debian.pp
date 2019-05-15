# Configure debian apt repo
#
# === Parameters
#
# [*location*]
#   Location of the apt repository
#
# [*release*]
#   Release of the apt repository
#
# [*repos*]
#   Apt repository names
#
# [*include_src*]
#   Add source source repository
#
# [*key*]
#   Public key in apt::key format
#
# [*dotdeb*]
#   Enable special dotdeb handling
#
class php::repo::debian(
  $location     = 'http://packages.dotdeb.org',
  $release      = 'wheezy-php56',
  $repos        = 'all',
  $include_src  = false,
  $key          = {
    'id'     => '6572BBEF1B5FF28B28B706837E3F070089DF5277',
    'source' => 'http://www.dotdeb.org/dotdeb.gpg',
  },
  $dotdeb       = true,
) {

  if $caller_module_name != $module_name {
    warning('php::repo::debian is private')
  }

  include '::apt'

  create_resources(::apt::key, { 'php::repo::debian' => {
    id     => $key['id'],
    source => $key['source'],
  }})

  ::apt::source { "source_php_${release}":
    location    => $location,
    release     => $release,
    repos       => $repos,
    include_src => $include_src,
    require     => Apt::Key['php::repo::debian'],
  }

  if ($dotdeb) {
    # both repositories are required to work correctly
    # See: http://www.dotdeb.org/instructions/
    if $release == 'wheezy-php56' {
      ::apt::source { 'dotdeb-wheezy':
        location    => $location,
        release     => 'wheezy',
        repos       => $repos,
        include_src => $include_src,
      }
    }
  }

  if ($php::globals::php_version == '7.1') {
    # Required packages for PHP 7.1 repository
    package { 'apt-transport-https':
      ensure => present,
    }

    package { 'lsb-release':
      ensure => present,
    }

    package { 'ca-certificates':
      ensure => present,
    }

    # Add PHP 7.1 key + repository
    create_resources(::apt::key, { 'php::repo::debian-php71' => {
      key => '15058500A0235D97F5D10063B188E2B695BD4743', key_source => 'https://packages.sury.org/php/apt.gpg',
    } })

    ::apt::source { 'source_php_71':
      location    => 'https://packages.sury.org/php/',
      release     => $::lsbdistcodename,
      repos       => 'main',
      include_src => false,
      require     => [
        Apt::Key['php::repo::debian-php71'],
        Package['apt-transport-https', 'lsb-release', 'ca-certificates']
      ],
    }
  }
}
