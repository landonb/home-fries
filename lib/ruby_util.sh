#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'path_prefix'
  check_dep 'path_suffix'

  HOMEFRIES_WARNINGS=${HOMEFRIES_WARNINGS:-false}
}

source_deps () {
  # See:
  #   https://github.com/postmodern/ruby-install
  #   https://github.com/postmodern/chruby
  if [ -f "${HOME}/.local/share/chruby/chruby.sh" ]; then
    . "${HOME}/.local/share/chruby/chruby.sh"
  elif [ -f /usr/local/share/chruby/chruby.sh ]; then
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
    if [ -f /usr/local/share/chruby/auto.sh ]; then
      . /usr/local/share/chruby/auto.sh
    fi
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_add_to_path_ruby_version_manager () {
  # 2017-04-27: Note that if you run script at https://get.rvm.io
  #             it'll append code to set PATH to your .bashrc.
  path_suffix "${HOME}/.rvm/bin"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ruby_set_gem_path () {
  local GEM_PATHS=()

  local RUBY_MINOR_ZERO=$(ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.') + '.0'")
  local RUBY_VERS=$(ruby -e "puts RUBY_VERSION")

  # E.g., ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0
  local ruby_path="${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}"
  if [ -d "${ruby_path}" ]; then
    GEM_PATHS+=(${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO})
  fi

  for ((i = 0; i < ${#GEM_PATHS[@]}; i++)); do
    local PATH_ELEM="${GEM_PATHS[$i]}"
    # echo "PATH_ELEM: $PATH_ELEM"
    if [ -d "${PATH_ELEM}" ]; then
      if [[ ":${GEM_PATH}:" != *":${PATH_ELEM}:"* ]]; then
        if [ -n "${GEM_PATH}" ]; then
          GEM_PATH="${GEM_PATH}:"
        fi
        GEM_PATH="${GEM_PATH}${PATH_ELEM}"
        # echo "GEM_PATH: $GEM_PATH"
      else
        # echo "Already added: $PATH_ELEM"
        :
      fi
    else
      # echo "Not a directory: $PATH_ELEM"
      :
    fi
  done
  export GEM_PATH

  #  echo "GEM_PATH=$GEM_PATH"

  # # GEM_PATH=${HOME}/.gem/ruby/2.3.0:/var/lib/gems/2.3.0
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
  path_prefix "${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}/bin"

  # 2017-06-26: For work, PATH should be to ~/.gems, not ~/.rubies.
  path_prefix "${HOME}/.gem/ruby/${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}/bin"
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

  # See chruby_use in
  #   /usr/local/share/chruby/chruby.sh
  #   ${HOME}/.local/share/chruby/chruby.sh

  # Here's our *monkey patch!*
  chruby_use () {
    orig_chruby_use $*
    # MAYBE: If you need to cleanup old paths, something like this:
    #          GEM_PATH="$(\
    #            echo ${GEM_PATH} \
    #            | /usr/bin/env sed -E "s@:?${GEM_HOME}[^:]*:@:@g" \
    #            | /usr/bin/env sed -E s/^:// \
    #            | /usr/bin/env sed -E s/:$//
    #          )"
    # Check if patch version.
    PATCH_NUM=$(ruby -e "puts RUBY_VERSION.split('.')[2]")
    if [ ${PATCH_NUM} -gt 0 ]; then
      # NOTE/2016-12-11: If there's a .ruby-version file in the current
      #   directory, running *any* command might invoke us, since auto.sh
      #   sets a trap on DEBUG which runs before every command. Just FYI.
      # MAYBE: Silence this echo. For now, curious when this fcn. is triggered.
      echo "Monkey patching!"
      ruby_set_gem_path
      # WRONG:
      #RUBY_ROOT_ZERO=$(echo ${RUBY_ROOT} | /usr/bin/env sed -E s/-${RUBY_VERSION}$/-${RUBY_MINOR_ZERO}/)
      #export PATH="${PATH}:${RUBY_ROOT_ZERO}/bin"
      #export PATH="${PATH}:${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
      local gem_ruby_bin="${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
      #if [[ ":${PATH}:" != *":${gem_ruby_bin}:"* ]]; then
      #  export PATH="${PATH}:${gem_ruby_bin}"
      #fi
      path_prefix ${gem_ruby_bin}
    fi
  }

  export -f chruby_use
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  source_deps
  unset -f source_deps

  home_fries_add_to_path_ruby_version_manager
  unset -f home_fries_add_to_path_ruby_version_manager

  # 2020-03-18: Wait to call: takes ~0.10 to call `ruby -e` twice.
  # - chruby_use will call ruby_set_gem_path.
  #  ruby_set_gem_path
  # Not unsetting: ruby_set_gem_path

  if ! ${HOMEFRIES_CHRUBY_SETUP:-false}; then
    patch_export_chruby_use
    export HOMEFRIES_CHRUBY_SETUP=true
  fi
  unset -f patch_export_chruby_use
}

main "$@"
unset -f main

