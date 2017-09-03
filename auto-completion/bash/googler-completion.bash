#
# Rudimentary Bash completion definition for googler.
#
# Author:
#   Zhiming Wang <zmwangx@gmail.com>
#

_googler () {
    COMPREPLY=()
    local IFS=$' \n'
    local cur=$2 prev=$3
    local -a opts opts_with_args
    opts=(
        -h --help
        -s --start
        -n --count
        -N --news
        -c --tld
        -l --lang
        -x --exact
        -C --nocolor
        --colors
        -j --first --lucky
        -t --time
        -w --site
        --unfilter
        -p --proxy
        --noua
        --notweak
        --json
        --url-handler
        --show-browser-logs
        --np --noprompt
        -u --upgrade
        --include-git
        -v --version
        -d --debug
    )
    opts_with_arg=(
        -s --start
        -n --count
        -c --tld
        -l --lang
        --colors
        -t --time
        -w --site
        -p --proxy
        --url-handler
    )

    if [[ $cur == -* ]]; then
        # The current argument is an option -- complete option names.
        COMPREPLY=( $(compgen -W "${opts[*]}" -- "$cur") )
    else
        # Do not complete option arguments; only autocomplete positional
        # arguments (queries).
        for opt in "${opts_with_arg[@]}"; do
            [[ $opt == $prev ]] && return 1
        done

        local completion
        COMPREPLY=()
        while IFS= read -r completion; do
            # Quote spaces for `complete -W wordlist`
            COMPREPLY+=( "${completion// /\\ }" )
        done < <(googler --complete "$cur")
    fi

    return 0
}

complete -F _googler googler
