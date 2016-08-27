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
    opts=(-c --tld -C --nocolor -d --debug -h --help --include-git -j --first --lucky --json
          -l --lang -n --count -N --news --noua --np --noprompt -p --proxy -s --start -t --time
          -U --upgrade --update -w --site -x --exact --enable-browser-output)
    opts_with_arg=(-c --tld --colors -l --lang -n --count -p --proxy -s --start -t --time -w --site)

    # Do not complete non option names
    [[ $cur == -* ]] || return 1

    # Do not complete when the previous arg is an option expecting an argument
    for opt in "${opts_with_arg[@]}"; do
        [[ $opt == $prev ]] && return 1
    done

    # Complete option names
    COMPREPLY=( $(compgen -W "${opts[*]}" -- "$cur") )
    return 0
}

complete -F _googler googler
