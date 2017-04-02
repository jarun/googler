#
# Rudimentary Bash completion definition for googler.
#
# Authors:
#   Zhiming Wang <zmwangx@gmail.com>
#   Jorge Maldonado Ventura <jorgesumle@freakspot.net>
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
        -p --proxy
        --noua
        --notweak
        --json
        --show-browser-logs
        --np --noprompt
        -u --upgrade
        --include-git
        -v --version
        -d --debug
    )
    opts_with_args=(
        -s --start
        -n --count
        -c --tld
        -l --lang
        --colors
        -t --time
        -w --site
        -p --proxy
    )

    # Do not complete non option names
    [[ $cur == -* ]] || return 1

    # Do not complete when the previous arg is an option expecting an argument
    for opt in "${opts_with_args[@]}"; do
        [[ $opt == $prev ]] && return 1
    done

    # Complete option names
    COMPREPLY=( $(compgen -W "${opts[*]}" -- "$cur") )
    return 0
}

complete -F _googler googler
