#
# Fish completion definition for googler.
#
# Author:
#   Arun Prakash Jana <engineerarun@gmail.com>
#

function __fish_googler_non_option_argument
    not string match -- "-*" (commandline -ct)
end

function __fish_googler_complete_query
    googler --complete (commandline -ct) ^/dev/null
end

complete -c googler -s h -l help              --description 'show help text and exit'
complete -c googler -s s -l start   -r        --description 'start at the Nth result'
complete -c googler -s n -l count   -r        --description 'show specified number of results (default 10)'
complete -c googler -s N -l news              --description 'show results from news section'
complete -c googler -s V -l videos            --description 'show results from videos section'
complete -c googler -s c -l tld     -r        --description 'country-specific search with top-level domain'
complete -c googler -s l -l lang    -r        --description 'display in specified language'
complete -c googler -s g -l geoloc  -r        --description 'specify geolocation code'
complete -c googler -s x -l exact             --description 'disable automatic spelling correction'
complete -c googler -l colorize     -r        --description 'whether to colorize output (options: auto/always/never)'
complete -c googler -s C -l nocolor           --description 'disable color output'
complete -c googler -l colors       -r        --description 'set output colors'
complete -c googler -s j -l first -l lucky    --description 'open the first result in a web browser'
complete -c googler -s t -l time    -r        --description 'time limit search (h/d/w/m/y + number)'
complete -c googler -l from         -r        --description 'starting date/month/year of date range'
complete -c googler -l to           -r        --description 'ending date/month/year of date range'
complete -c googler -s w -l site    -r        --description 'search a site using Google'
complete -c googler -s e -l exclude -r        --description 'exclude site from results'
complete -c googler -l unfilter               --description 'do not omit similar results'
complete -c googler -s p -l proxy   -r        --description 'proxy in HOST:PORT format'
complete -c googler -l notweak                --description 'disable TCP optimizations, forced TLS 1.2'
complete -c googler -l json                   --description 'output in JSON format'
complete -c googler -l url-handler  -r        --description 'cli script or utility'
complete -c googler -l show-browser-logs      --description 'do not suppress browser output'
complete -c googler -l np -l noprompt         --description 'perform search and exit'
complete -c googler -s u -l upgrade           --description 'perform in-place self-upgrade'
complete -c googler -l include-git            --description 'use git master for --upgrade'
complete -c googler -s v -l version           --description 'show version number and exit'
complete -c googler -s d -l debug             --description 'enable debugging'
complete -c googler -n __fish_googler_non_option_argument -a '(__fish_googler_complete_query)'
