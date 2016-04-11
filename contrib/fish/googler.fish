#
# fish completion definition for googler.
#
# Author:
#   Arun Prakash Jana <engineerarun@gmail.com>
#
complete -c googler -s s -l start          --description 'start at the Nth result'
complete -c googler -s n -l count          --description 'show N results (default 10)'
complete -c googler -s N -l news           --description 'show results from news section'
complete -c googler -s c -l tld            --description 'country-specific search with top-level domain .TLD'
complete -c googler -s l -l lang           --description 'display in language LANG'
complete -c googler -s x -l exact          --description 'disable automatic spelling correction'
complete -c googler -s C -l nocolor        --description 'disable color output'
complete -c googler -s j -l first -l lucky --description 'open the first result in a web browser'
complete -c googler -s t -l time           --description 'time limit search [e.g. h5, d5, w5, m5, y5]'
complete -c googler -s w -l site           --description 'search a site using Google'
complete -c googler -s d -l debug          --description 'enable debugging'
