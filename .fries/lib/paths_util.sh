#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: paths_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** PATH builder

path_add_part () {
  local path_part="$1"
  if [[ -d "${path_part}" ]]; then
    # We could do nothing if the path part is already indicated:
    #
    #   if [[ ":$PATH:" != *":${path_part}:"* ]]; then
    #     ..
    #   fi
    #
    # but path_add_part guarantees the new part is positioned
    # at first place, so remove it first.
    #
    # Substitute: s/^prefix://
    PATH=${PATH#${path_part}:}
    # Substitute: s/:suffix$//
    PATH=${PATH%:${path_part}}
    # Substitute: s/^sole-path$//
    if [[ ${PATH} == ${path_part} ]]; then
      PATH=""
    fi
    # Substitute: s/:inside:/:/
    PATH=${PATH/:${path_part}:/:}
    # Now we're ready to prepend it.
    PATH="${path_part}:${PATH}"
    #
    export PATH
  #else
  #  echo "path_add_part: Not a directory: ${path_part}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_set_path_environ() {
  # Home-fries scripts are in ~/.fries/bin. Third-party applications installed
  # by custom_setup.extras.sh et al are installed to /srv/opt/bin.

  # 2016-12-06: To avoid making PATH super long -- mostly just an annoyance
  # if you want to look at, but not a performance issue or anything -- which
  # happens if you reload your .bashrc by running /bin/bash from a terminal,
  # collect all the PATH additions and then add them only if not added.
  local path_prefix=()
  local path_suffix=()

  # Binary fries.
  path_prefix+=("${HOMEFRIES_DIR}/bin")
  # 2017-10-03: Make sourcing files easy!
  path_prefix+=("${HOMEFRIES_DIR}/lib")

  # /srv/opt/bin
  path_prefix+=("${OPT_BIN}")
  # 2017-02-25: /srv/opt/bin/bin
  path_prefix+=("${OPT_BIN}/bin")

  # ~/.local/bin is where, e.g., `pip install --user blah` installs.
  path_suffix+=("${HOME}/.local/bin")

  # Android Studio.
  JAVA_HOME=${OPT_BIN}/jdk
  JRE_HOME=$JAVA_HOME/jre
  if [[ -d ${JAVA_HOME} ]]; then
    path_prefix+=("${JAVA_HOME}/bin:${JRE_HOME}/bin")
  fi
  if [[ -d ${OPT_BIN}/android-studio/bin ]]; then
    path_suffix+=("${OPT_BIN}/android-studio/bin")
  fi
  if [[ -d ${OPT_BIN}/android-sdk/platform-tools ]]; then
    path_suffix+=("${OPT_BIN}/android-sdk/platform-tools")
  fi
  # 2017-02-25: Have I been missing ANDROID_HOME for this long??
  export ANDROID_HOME=${HOME}/Android/Sdk
  if [[ ":${PATH}:" != *":${ANDROID_HOME}/tools:"* ]]; then
    export PATH=${PATH}:${ANDROID_HOME}/tools
  fi

  # No whep. 2016.04.28 and this is the first time I've seen this.
  #   $ ifconfig
  #   Command 'ifconfig' is available in '/sbin/ifconfig'
  #   The command could not be located because '/sbin' is not included in the PATH environment variable.
  #   This is most likely caused by the lack of administrative privileges associated with your user account.
  #   ifconfig: command not found
  path_suffix+=("/sbin")

  # 2016-07-11: Google Go, for Google Drive `drive`.
  #
  # The latest go binary.
  if [[ -d /usr/local/go/bin ]]; then
    path_prefix+=("/usr/local/go/bin")
  fi
  if [[ ! -d ${HOME}/.gopath ]]; then
    # 2016-10-03: Why not?
    mkdir ${HOME}/.gopath
  fi
  if [[ -d ${HOME}/.gopath ]]; then
    # Local go projects you install.
    export GOPATH=${HOME}/.gopath
    # Check with: `go env`

    path_prefix+=("${GOPATH}:${GOPATH}/bin")
  fi

  # OpenShift Origin server.
  if [[ -d ${OPT_BIN}/openshift-origin-server ]]; then
    path_suffix+=("${OPT_BIN}/openshift-origin-server")

    # OpenShift development.
    #  https://github.com/openshift/origin/blob/master/CONTRIBUTING.adoc#develop-locally-on-your-host
    # Used in one place:
    #  /exo/clients/openshift/origin/hack/common.sh
    export OS_OUTPUT_GOPATH=1
  fi

  # 2016-11-18: What a jerk! Heroku Toolbelt just shat this at
  # the end of my ~/.bashrc, which is a symlink to, well, you
  # know. An Important File. Get out of there! And you didn't
  # even use a trailing newline. Why to respk house rulz, bruh.
  #
  #     ### Added by the Heroku Toolbelt
  #     export NEW_PATHS+=("/usr/local/heroku/bin:$PATH")
  #
  # Also, shouldn't you be at the _end_ of the conga line?
  # And what ever happened to being polite and checking for
  # existence?
  if [[ -d /usr/local/heroku/bin ]]; then
    path_suffix+=("/usr/local/heroku/bin")
  fi

  # 2016-12-03: I guess MrMurano is my first gem.
  # 2016-12-08: Looks like `chruby` updates PATH for us.
  #  if type -P ruby &>/dev/null; then
  #    # Determine the user's rubygems path. E.g.,
  #    #   ~/.gem/ruby/1.9.1
  #    ruby_gem_path=$(ruby -rubygems -e 'puts Gem.user_dir')
  #    if [[ -n ${ruby_gem_path} ]]; then
  #      path_suffix+=("${ruby_gem_path}")
  #      path_suffix+=("${ruby_gem_path}/bin")
  #    fi
  #  fi
  #
  # FIXME/2016-12-08: Probably need to figure out how to handle chruby, e.g.,
  # $ chruby ruby-2.3.3
  # $ gem install --user-install bundler pry byebug commander rubocop terminal-table httparty
  # Fetching: bundler-1.13.6.gem (100%)
  # WARNING:  You don't have /home/landonb/.gem/ruby/2.3.0/bin in your PATH,
  # 	  gem executables will not run.
  # ...
  #
  # MAYBE: just override chruby to fix PATH?

  if [[ -d ${OPT_DLOADS}/abcde-2.8.1 ]]; then
    path_suffix+=("${OPT_DLOADS}/abcde-2.8.1")
  fi

  # 2017-04-27: Added by Bash script at https://get.rvm.io:
  #   "Add RVM to PATH for scripting. Make sure this is the last PATH variable change."
  if [[ -d ${HOME}/.rvm/bin ]]; then
    path_suffix+=("${HOME}/.rvm/bin")
  fi

  # 2017-10-10...
  if [[ -d ${OPT_DLOADS}/WebStorm-172.4155.35/bin ]]; then
    path_suffix+=("${OPT_DLOADS}/WebStorm-172.4155.35/bin")
  fi

  # ============================
  # Cleanup PATH before export
  # ============================

  # 2016-12-06: Check if directory in PATH or not (so PATH doesn't
  # just become really long if you run /bin/bash from a shell).
  #   https://stackoverflow.com/questions/1396066/
  #     detect-if-users-path-has-a-specific-directory-in-it
  #   "Using grep is overkill, and can cause trouble if you're searching for
  #   anything that happens to include RE metacharacters. This problem can be
  #   solved perfectly well with bash's builtin [[ command:" [... see below.]

  local path_elem=""

  for ((i = 0; i < ${#path_prefix[@]}; i++)); do
    path_elem="${path_prefix[$i]}"
    # Similar to:
    #  path_add_part "${path_elem}"
    if [[ ":${PATH}:" != *":${path_elem}:"* ]]; then
      PATH="${path_elem}:${PATH}"
    fi
  done

  for ((i = 0; i < ${#path_suffix[@]}; i++)); do
    path_elem="${path_suffix[$i]}"
    if [[ ":${PATH}:" != *":${path_elem}:"* ]]; then
      PATH="${PATH}:${path_elem}"
    fi
  done

  export PATH
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"
