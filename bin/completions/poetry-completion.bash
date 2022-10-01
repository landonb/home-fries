_poetry_00ca21d708b31f58_complete()
{
    local cur script coms opts com
    COMPREPLY=()
    _get_comp_words_by_ref -n : cur words

    # for an alias, get the real script behind it
    if [[ $(type -t ${words[0]}) == "alias" ]]; then
        script=$(alias ${words[0]} | sed -E "s/alias ${words[0]}='(.*)'/\1/")
    else
        script=${words[0]}
    fi

    # lookup for command
    for word in ${words[@]:1}; do
        if [[ $word != -* ]]; then
            com=$word
            break
        fi
    done

    # completing for an option
    if [[ ${cur} == --* ]] ; then
        opts="--ansi --help --no-ansi --no-cache --no-interaction --no-plugins --quiet --verbose --version"

        case "$com" in

            (about)
            opts="${opts} "
            ;;

            (add)
            opts="${opts} --allow-prereleases --dev --dry-run --editable --extras --group --lock --optional --platform --python --source"
            ;;

            (build)
            opts="${opts} --format"
            ;;

            # [lb] 2022-09-30: Bug in python-poetry/cleo produces invalid Bash,
            # e.g.,:
            #  (cache clear)
            # This issue is fixed upstream but not released yet. Cleo is a
            # Poetry dependency, and I'd rather not spend time wiring cleo
            # installation, so patching herein in the meantime.
            # - REFER: https://github.com/python-poetry/poetry/issues/6523
            #
            # (cache clear)
            # opts="${opts} --all"
            # ;;
            #
            # (cache list)
            # opts="${opts} "
            # ;;
            (cache)
            opts="${opts} --all"
            ;;

            (check)
            opts="${opts} "
            ;;

            (config)
            opts="${opts} --list --local --unset"
            ;;

            # [lb] 2022-09-30: See bug comment above re: cleo issues/6523.
            #
            # (debug info)
            # opts="${opts} "
            # ;;
            #
            # (debug resolve)
            # opts="${opts} --extras --install --python --tree"
            # ;;
            (debug)
            opts="${opts} --extras --install --python --tree"
            ;;

            (dynamic-versioning)
            opts="${opts} "
            ;;

            # [lb] 2022-09-30: See bug comment above re: cleo issues/6523.
            #
            # (env info)
            # opts="${opts} --path"
            # ;;
            #
            # (env list)
            # opts="${opts} --full-path"
            # ;;
            #
            # (env remove)
            # opts="${opts} --all"
            # ;;
            #
            # (env use)
            # opts="${opts} "
            # ;;
            (env)
            opts="${opts} --path --full-path --all"
            ;;

            (export)
            opts="${opts} --dev --extras --format --only --output --with --with-credentials --without --without-hashes --without-urls"
            ;;

            (help)
            opts="${opts} "
            ;;

            (init)
            opts="${opts} --author --dependency --description --dev-dependency --license --name --python"
            ;;

            (install)
            opts="${opts} --all-extras --dry-run --extras --no-dev --no-root --only --only-root --remove-untracked --sync --with --without"
            ;;

            (list)
            opts="${opts} "
            ;;

            (lock)
            opts="${opts} --check --no-update"
            ;;

            (new)
            opts="${opts} --name --readme --src"
            ;;

            (publish)
            opts="${opts} --build --cert --client-cert --dry-run --password --repository --skip-existing --username"
            ;;

            (remove)
            opts="${opts} --dev --dry-run --group"
            ;;

            (run)
            opts="${opts} "
            ;;

            (search)
            opts="${opts} "
            ;;

            # [lb] 2022-09-30: See bug comment above re: cleo issues/6523.
            #
            # (self add)
            # opts="${opts} --allow-prereleases --dry-run --editable --extras --source"
            # ;;
            #
            # (self install)
            # opts="${opts} --dry-run --sync"
            # ;;
            #
            # (self lock)
            # opts="${opts} --check --no-update"
            # ;;
            #
            # (self remove)
            # opts="${opts} --dry-run"
            # ;;
            #
            # (self show)
            # opts="${opts} --addons --latest --outdated --tree"
            # ;;
            #
            # (self show plugins)
            # opts="${opts} "
            # ;;
            #
            # (self update)
            # opts="${opts} --dry-run --preview"
            # ;;
            (self)
            opts="${opts} --allow-prereleases --dry-run --editable --extras --source --sync --check --no-update --addons --latest --outdated --tree --preview --all --no-dev --only --why --with --without"
            ;;

            # [lb] 2022-09-30: See bug comment above re: cleo issues/6523.
            #
            # (source add)
            # opts="${opts} --default --secondary"
            # ;;
            #
            # (source remove)
            # opts="${opts} "
            # ;;
            #
            # (source show)
            # opts="${opts} "
            # ;;
            (source)
            opts="${opts} --default --secondary"
            ;;

            (update)
            opts="${opts} --dry-run --lock --no-dev --only --with --without"
            ;;

            (version)
            opts="${opts} --dry-run --short"
            ;;

        esac

        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
        __ltrim_colon_completions "$cur"

        return 0;
    fi

    # completing for a command
    if [[ $cur == $com ]]; then
        coms="about add build cache clear cache list check config debug info debug resolve dynamic-versioning env info env list env remove env use export help init install list lock new publish remove run search self add self install self lock self remove self show self show plugins self update shell show source add source remove source show update version"

        COMPREPLY=($(compgen -W "${coms}" -- ${cur}))
        __ltrim_colon_completions "$cur"

        return 0
    fi
}

complete -o default -F _poetry_00ca21d708b31f58_complete poetry
complete -o default -F _poetry_00ca21d708b31f58_complete /home/landonb/.local/share/pypoetry/venv/bin/poetry

# [lb]: Hacking in my `alias po`.
complete -o default -F _poetry_00ca21d708b31f58_complete po

