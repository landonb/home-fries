#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  DEBUG_TRACE=false \
    . ${curdir}/bash_base.sh
  # Load: path_append, path_prepend
  . ${curdir}/paths_util.sh

  # See:
  #   https://github.com/postmodern/ruby-install
  #   https://github.com/postmodern/chruby
  if [[ -f ${HOME}/.local/share/chruby/chruby.sh ]]; then
    . ${HOME}/.local/share/chruby/chruby.sh
  elif [[ -f /usr/local/share/chruby/chruby.sh ]]; then
    . /usr/local/share/chruby/chruby.sh
  fi

  # The github.com/postmodern/chruby README lists Anti-Features, starting with:
  #   - Does not hook cd.
  #   - Does not install executable shims.
  # However, it doesn't say what it does do instead!
  #   chruby/auto.sh sets a trap on DEBUG,
  #   and if $BASH_COMMAND != $PROMPT_COMMAND,
  #   it walks up the directory tree looking
  #   for a .ruby-version file on which to chruby.
  # Cmd:
  #   trap '[[ "$BASH_COMMAND" != "$PROMPT_COMMAND" ]] && chruby_auto' DEBUG
  # Ref:
  #   BASH_COMMAND
  #     The  command  currently  being  executed or about to be executed,
  #     unless the shell is executing a command as the result of a trap,
  #     in which case it is the command executing at the time of the trap.
  #   PROMPT_COMMAND
  #     If set, the value is executed as a command prior to issuing each
  #     primary prompt.
  #   DEBUG
  #     Refer to the description of the extdebug option to the shopt builtin
  #     for details of its effect  on  the  DEBUG  trap.
  #   extdebug
  #     If set, behavior intended for use by debuggers is enabled:
  #     1.     The  -F option to the declare builtin displays the source file name and line number corresponding
  #            to each function name supplied as an argument.
  #     2.     If the command run by the DEBUG trap returns a non-zero value, the next command  is  skipped  and
  #            not executed.
  #     3.     If  the  command run by the DEBUG trap returns a value of 2, and the shell is executing in a sub‐
  #            routine (a shell function or a shell script executed by the . or  source  builtins),  a  call  to
  #            return is simulated.
  #     4.     BASH_ARGC and BASH_ARGV are updated as described in their descriptions above.
  #     5.     Function tracing is enabled:  command substitution, shell functions, and subshells invoked with (
  #            command ) inherit the DEBUG and RETURN traps.
  #     6.     Error tracing is enabled:  command substitution, shell functions, and subshells  invoked  with  (
  #            command ) inherit the ERR trap.
  # So:
  #   Every time you run *any* command, auto.sh
  #   crawls the tree looking for .ruby-version.

  # 2017-05-03: I'm disabling this. Seems redonkulous.
  # You have ``gogo`` command et al to accomplish same.
  # And then you're not spinning up dir every time you
  # run a Bash command. And it's not not that's slow,
  # it's just the principal of the thing, man.
  if false; then
    if [[ -f /usr/local/share/chruby/auto.sh ]]; then
      . /usr/local/share/chruby/auto.sh
    fi
  fi

  if [[ -z ${HOMEFRIES_WARNINGS+x} ]]; then
    # Usage, e.g.:
    #   HOMEFRIES_WARNINGS=true bash
    HOMEFRIES_WARNINGS=false
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_add_to_path_ruby_version_manager () {
  # 2017-04-27: Note that if you run script at https://get.rvm.io
  #             it'll append code to set PATH to your .bashrc.
  path_append "${HOME}/.rvm/bin"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ruby_set_gem_path () {
  local GEM_PATHS=()

  local RUBY_MINOR_ZERO=$(ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.') + '.0'")
  local RUBY_VERS=$(ruby -e "puts RUBY_VERSION")

  if false; then
    # 2017-05-03: I started having issues at work... I think this is all too much!

    if ``command -v ruby >/dev/null 2>&1``; then
      # E.g., ${HOME}/.gem/ruby/2.3.0
      GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_MINOR_ZERO})
      # 2017-05-03: MAYBE: Do we need this one, too? If anything, it's same as previous.
      GEM_PATHS+=($(ruby -rubygems -e 'puts Gem.user_dir'))
    fi
    GEM_PATHS+=(${HOME}/.rubies/ruby-${RUBY_MINOR_ZERO}/lib/ruby/gems/${RUBY_MINOR_ZERO})
    # 2017-05-03: I am so confused.
    # E.g., ${HOME}/.gem/ruby/2.3.0/ruby/2.3.0
    GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_MINOR_ZERO}/ruby/${RUBY_MINOR_ZERO})
    # E.g., ${HOME}/.gem/ruby-2.3.3/ruby/2.3.0
    GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO})
    # 2017-01-25: Haven't touched a project in one month, and now it's not working?
    #   Am I on a different machine, or what? Anyway, missing /var/lib/gems, I guess!
    # E.g., /var/lib/gems/2.3.0
    # 2017-05-03 14:38: ARGH: apt-get install binaries are in /var/lib/gems,
    #   not the ones controlled by chruby, rvm, etc.
    #GEM_PATHS+=(/var/lib/gems/${RUBY_MINOR_ZERO})
  fi

  # E.g., ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0
  local ruby_path="${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}"
  if [[ -d ${ruby_path} ]]; then
    GEM_PATHS+=(${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO})
  fi

  for ((i = 0; i < ${#GEM_PATHS[@]}; i++)); do
    local PATH_ELEM="${GEM_PATHS[$i]}"
    #echo "PATH_ELEM: $PATH_ELEM"
    if [[ -d "${PATH_ELEM}" ]]; then
      if [[ ":${GEM_PATH}:" != *":${PATH_ELEM}:"* ]]; then
        if [[ -n ${GEM_PATH} ]]; then
          GEM_PATH="${GEM_PATH}:"
        fi
        GEM_PATH="${GEM_PATH}${PATH_ELEM}"
        #echo "GEM_PATH: $GEM_PATH"
      else
        #echo "Already added: $PATH_ELEM"
        :
      fi
    else
      #echo "Not a directory: $PATH_ELEM"
      :
    fi
  done
  #echo "GEM_PATH: $GEM_PATH"

  export GEM_PATH

  if true; then
    # $ echo $GEM_PATH
    # ${HOME}/.gem/ruby/2.3.0:/var/lib/gems/2.3.0
    # $ gogo project
    # Skipping ~/.exoline symlink: no replacement found.
    # Entered /work/clients/project
    # $ ll
    # Ignoring byebug-9.0.6 because its extensions are not built.  Try: gem pristine byebug --version 9.0.6
    # Monkey patching!
    # total 188K
    # drwxrwxr-x 11 landonb landonb 4.0K May  1 18:41 ./
    # drwxrwxr-x  7 landonb landonb 4.0K May  1 14:08 ../
    # ...

    # E.g., ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0/bin
    path_prepend ${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}/bin

    # 2017-06-26: For work, PATH should be to ~/.gems, not ~/.rubies.
    path_prepend ${HOME}/.gem/ruby/${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}/bin
  fi

  if false; then
    # Put this at first place in the PATH. If it exists.
    path_prepend ${HOME}/.gem/ruby/${RUBY_MINOR_ZERO}/bin
    path_prepend ${HOME}/.gem/ruby/${RUBY_VERS}/bin
  fi

}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

patch_export_chruby_use () {
  # Here we monkey patch the chruby function -- we replace
  # the chruby fcn. with our own wrapper function.
  # MAYBE: I should probably just submit a pull request.
  #
  # PROBLEM: If the ruby version is not the 0 patch level (e.g., 2.3.0),
  #   chruby doesn't include all the gem paths. For example, should you
  #   `chruby 2.3.3`, GEM_PATH includes the 2.3.3/ directory, but gem install
  #   stashed everything under the 2.3.0/ directory, so we have to add that
  #   back in.

  # Do a little Bash trickery: Spit out the original function and set it up
  #   under a new name. We use `tail -n +2` to remove the original function
  #   name but leave the function body, e.g., leave out ``chruby_use ()\n``.

  orig_chruby_use () {
    :
  }
  if declare -f chruby_use &> /dev/null; then
    eval "$(echo "orig_chruby_use()"; declare -f chruby_use | tail -n +2)"
  else
    $HOMEFRIES_WARNINGS && echo "WARNING: chruby_use() not found"
  fi

  # And here's our
  #   MONKEY PATCH!
  chruby_use () {
    orig_chruby_use $*
    # See chruby_use in
    #   /usr/local/share/chruby/chruby.sh
    #   ${HOME}/.local/share/chruby/chruby.sh
    # MAYBE: If you need to cleanup old paths, something like this:
    if false; then
      export GEM_PATH="$(\
        echo ${GEM_PATH} \
          | /bin/sed -E "s@:?${GEM_HOME}[^:]*:@:@g" \
          | /bin/sed -E s/^:// \
          | /bin/sed -E s/:$//
      )"
    fi
    # Check if patch version.
    PATCH_NUM=$(ruby -e "puts RUBY_VERSION.split('.')[2]")
    if [[ ${PATCH_NUM} -gt 0 ]]; then
      # NOTE/2016-12-11: If there's a .ruby-version file in the current
      #   directory, running *any* command might invoke us, since auto.sh
      #   sets a trap on DEBUG which runs before every command. Just FYI.
      # MAYBE: Silence this echo. For now, curious when this fcn. is triggered.
      echo "Monkey patching!"
      ruby_set_gem_path
      # WRONG:
      #RUBY_ROOT_ZERO=$(echo ${RUBY_ROOT} | /bin/sed -E s/-${RUBY_VERSION}$/-${RUBY_MINOR_ZERO}/)
      #export PATH="${PATH}:${RUBY_ROOT_ZERO}/bin"
      #export PATH="${PATH}:${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
      local gem_ruby_bin="${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
      #if [[ ":${PATH}:" != *":${gem_ruby_bin}:"* ]]; then
      #  export PATH="${PATH}:${gem_ruby_bin}"
      #fi
      path_prepend ${gem_ruby_bin}
    fi
  }

  export -f chruby_use
}

# 2018-09-17: A wrapper I made to support installing same Ruby version
# multiple times. Had to re-write wrapper because ~/.gem path hardcoded!
#
# See also:
#
#   - "Manage your rubies with direnv and ruby-install"
#
#     https://github.com/direnv/direnv/blob/master/docs/ruby.md
chruby_use_GEMZ_DIR () {
  if [[ ! -x "$1/bin/ruby" ]]; then
    echo "chruby: $1/bin/ruby not executable" 1>&2;
    return 1;
  fi;
  [[ -n "$RUBY_ROOT" ]] && chruby_reset;
  export RUBY_ROOT="$1";
  export RUBYOPT="$2";
  export PATH="$RUBY_ROOT/bin:$PATH";
  eval "$("$RUBY_ROOT/bin/ruby" - <<EOF
puts "export RUBY_ENGINE=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "export RUBY_VERSION=#{RUBY_VERSION};"
begin; require 'rubygems'; puts "export GEM_ROOT=#{Gem.default_dir.inspect};"; rescue LoadError; end
EOF
)";
  if (( $UID != 0 )); then
    export GEM_HOME="$HOME/.gemz/$RUBY_ENGINE/$RUBY_VERSION";
    export GEM_PATH="$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}";
    export PATH="$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$PATH";
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2017-06-19: So confused.
# At work, `cmd rspec` indicates ???.
# At home, it's ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0/bin/rspec
# At work, rspec could not find the rainbow gem,
# because it's RUBY_VERSION was 2.3.1, not 2.3.3.
#    $ alias rspec=~/.gem/ruby/2.3.3/ruby/2.3.0/bin/rspec
#    @home $ locate rspec | grep "\/rspec$"
#    ~/.gem/ruby/2.3.0/ruby/2.3.0/bin/rspec -v    <== 3.5.4
#    ~/.gem/ruby/2.3.3/ruby/2.3.0/bin/rspec -v    <== 3.5.4
#    ~/.rubies/ruby-2.3.3/ruby/2.3.0/bin/rspec -v <== 3.5.4
#    hrmmm...
ruby_set_rspec_alias () {
  : # FIXME: Maybe write this for work.
}
#ruby_set_rspec_alias
unset -f ruby_set_rspec_alias

# 2017-06-25 18:24
# alias rake=/home/landonb/.rubies/ruby-2.3.3/bin/rake

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_ruby_util () {
  unset -f source_deps

  unset -f home_fries_add_to_path_ruby_version_manager

  # So meta.
  unset -f unset_f_ruby_util
}

main () {
  source_deps
  unset -f source_deps

  home_fries_add_to_path_ruby_version_manager
  unset -f home_fries_add_to_path_ruby_version_manager

  ruby_set_gem_path

  if [[ -z ${HOMEFRIES_CHRUBY_SETUP+x} ]]; then
    patch_export_chruby_use
# . ruby_chutil.sh
    export HOMEFRIES_CHRUBY_SETUP=true
  fi
  unset -f patch_export_chruby_use
}

main "$@"
unset -f main

