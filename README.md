<h1 align="center"><img src="https://cdn.rawgit.com/jarun/googler/master/googler.svg" alt="googler" /></h1>

<p align="center">
<a href="https://github.com/jarun/googler/releases/latest"><img src="https://img.shields.io/github/release/jarun/googler.svg?maxAge=600" alt="Latest release" /></a>
<a href="https://aur.archlinux.org/packages/googler"><img src="https://img.shields.io/aur/version/googler.svg?maxAge=600" alt="AUR" /></a>
<a href="http://formulae.brew.sh/formula/googler"><img src="https://img.shields.io/homebrew/v/googler.svg?maxAge=600" alt="Homebrew" /></a>
<a href="https://packages.debian.org/search?keywords=googler&searchon=names"><img src="https://img.shields.io/badge/debian-9+-blue.svg?maxAge=2592000" alt="Debian Stretch+" /></a>
<a href="https://packages.ubuntu.com/search?keywords=googler&searchon=names"><img src="https://img.shields.io/badge/ubuntu-16.10+-blue.svg?maxAge=2592000" alt="Ubuntu Yakkety+" /></a>
<a href="https://github.com/jarun/googler/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-yellow.svg?maxAge=2592000" alt="License" /></a>
<a href="https://travis-ci.org/jarun/googler"><img src="https://travis-ci.org/jarun/googler.svg?branch=master" alt="Build Status" /></a>
</p>

<p align="center">
<a href="https://asciinema.org/a/85019"><img src="https://s1.postimg.org/1hg2x1dqrj/googler.png" alt="Asciicast" width="734"/></a>
</p>

`googler` is a power tool to Google (Web & News) and Google Site Search from the command-line. It shows the title, URL and abstract for each result, which can be directly opened in a browser from the terminal. Results are fetched in pages (with page navigation). Supports sequential searches in a single `googler` instance.

`googler` was initially written to cater to headless servers without X. You can integrate it with a text-based browser. However, it has grown into a very handy and flexible utility that delivers much more. For example, fetch any number of results or start anywhere, limit search by any duration, define aliases to google search any number of websites, switch domains easily... all of this in a very clean interface without ads or stray URLs. The shell completion scripts make sure you don't need to remember any options.

`googler` isn't affiliated to Google in any way.

*Looking for a similar utility for privacy-aware DuckDuckGo?* Check out [`ddgr`](https://github.com/jarun/ddgr)!

*Love smart and efficient terminal utilities? Explore my repositories. Buy me a cup of coffee if they help you.*

<p align="center">
<a href="https://saythanks.io/to/jarun"><img src="https://img.shields.io/badge/say-thanks!-ff69b4.svg" /></a>
<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RMLTQ76JSXJ4Q"><img src="https://img.shields.io/badge/PayPal-donate-green.svg" alt="Donate via PayPal!" /></a>
</p>

### Table of contents

- [Features](#features)
- [Installation](#installation)
    - [Dependencies](#dependencies)
    - [From a package manager](#from-a-package-manager)
        - [Tips for packagers](#tips-for-packagers)
    - [Release packages](#release-packages)
    - [From source](#from-source)
    - [Running standalone](#running-standalone)
    - [Downloading a single file](#downloading-a-single-file)
- [Shell completion](#shell-completion)
- [Usage](#usage)
    - [Cmdline options](#cmdline-options)
    - [Configuration file](#configuration-file)
    - [googler @t](#googler-t)
    - [Text-based browser integration](#text-based-browser-integration)
    - [Terminal Reading Mode or Reader View](#terminal-reading-mode-or-reader-view)
    - [Colors](#colors)
    - [Domain-only URL](#domain-only-url)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Notes](#notes)
- [Contributions](#contributions)
- [Developers](#developers)

### Features

- Google Search, Google Site Search, Google News
- Fast and clean (no ads, stray URLs or clutter), custom color
- Navigate result pages from omniprompt, open URLs in browser
- Effortless keyword-based site search with googler @t add-on
- Search and option completion scripts for Bash, Zsh and Fish
- Fetch n results in a go, start at the n<sup>th</sup> result
- Disable automatic spelling correction and search exact keywords
- Specify duration, country/domain (default: worldwide/.com), language
- Google keywords (e.g. `filetype:mime`, `site:somesite.com`) support
- Open the first result directly in browser (as in *I'm Feeling Lucky*)
- Non-stop searches: fire new searches at omniprompt without exiting
- HTTPS proxy, User Agent, TLS 1.2 (default) support
- Comprehensive documentation, man page with handy usage examples
- Minimal dependencies

### Installation

#### Dependencies

`googler` requires Python 3.4 or later. Only the latest patch release of each minor version is supported.

To copy url to clipboard at the omniprompt, `googler` uses `xsel` on Linux, `pbcopy` (default installed) on OS X and `clip` (default installed) on Windows.

#### From a package manager

- [AUR](https://aur.archlinux.org/packages/googler/)
- [Debian](https://packages.debian.org/search?keywords=googler&searchon=names)
- [FreeBSD](https://www.freshports.org/www/googler/) (`pkg install googler`)
- [Homebrew](http://formulae.brew.sh/formula/googler)
- [NixOS](https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/misc/googler) (`sudo nix-env -i googler`)
- [openSUSE](https://software.opensuse.org/package/googler)
- [Slackware](http://slackbuilds.org/repository/14.2/network/googler/)
- [Ubuntu](https://packages.ubuntu.com/search?keywords=googler&searchon=names)
- [Ubuntu PPA](https://launchpad.net/~twodopeshaggy/+archive/ubuntu/jarun/)
- [Void Linux](https://github.com/voidlinux/void-packages/blob/master/srcpkgs/googler/template) (`sudo xbps-install -S googler`)

##### Tips for packagers

`googler` v2.7 and later ships with an in-place self-upgrade mechanism which you may want to disable. To do this, run

    $ make disable-self-upgrade

before installation.

#### Release packages

Packages for Arch Linux, CentOS, Debian, Fedora, openSUSE Leap and Ubuntu are available with the [latest stable release](https://github.com/jarun/googler/releases/latest).

#### From source

If you have git installed, clone this repository. Otherwise download the [latest stable release](https://github.com/jarun/googler/releases/latest) or [development version](https://github.com/jarun/googler/archive/master.zip).

To install to the default location (`/usr/local`):

    $ sudo make install

To remove `googler` and associated docs, run

    $ sudo make uninstall

`PREFIX` is supported, in case you want to install to a different location.

#### Running standalone

`googler` is a standalone executable. From the containing directory:

    $ ./googler

#### Downloading a single file

`googler` is a single standalone script, so you could download just a single file if you'd like to.

To install the latest stable version, run

    $ sudo curl -o /usr/local/bin/googler https://raw.githubusercontent.com/jarun/googler/v3.5/googler && sudo chmod +x /usr/local/bin/googler

You could then let googler upgrade itself by running

    $ sudo googler -u

Similarly, if you want to install from git master (*risky*), run

    $ sudo curl -o /usr/local/bin/googler https://raw.githubusercontent.com/jarun/googler/master/googler && sudo chmod +x /usr/local/bin/googler

and upgrade by running

    $ sudo googler -u --include-git

### Shell completion

Search keyword and option completion scripts for Bash, Fish and Zsh can be found in respective subdirectories of [`auto-completion/`](auto-completion). Please refer to your shell's manual for installation instructions.

### Usage

#### Cmdline options

```
usage: googler [-h] [-s N] [-n N] [-N] [-c TLD] [-l LANG] [-x] [-C]
               [--colors COLORS] [-j] [-t dN] [-w SITE] [--unfilter]
               [-p PROXY] [--noua] [--notweak] [--json] [--url-handler UTIL]
               [--show-browser-logs] [--np] [-u] [--include-git] [-v] [-d]
               [KEYWORD [KEYWORD ...]]

Google from the command-line.

positional arguments:
  KEYWORD               search keywords

optional arguments:
  -h, --help            show this help message and exit
  -s N, --start N       start at the Nth result
  -n N, --count N       show N results (default 10)
  -N, --news            show results from news section
  -c TLD, --tld TLD     country-specific search with top-level domain .TLD,
                        e.g., 'in' for India
  -l LANG, --lang LANG  display in language LANG
  -x, --exact           disable automatic spelling correction
  -C, --nocolor         disable color output
  --colors COLORS       set output colors (see man page for details)
  -j, --first, --lucky  open the first result in web browser and exit
  -t dN, --time dN      time limit search [h5 (5 hrs), d5 (5 days), w5 (5
                        weeks), m5 (5 months), y5 (5 years)]
  -w SITE, --site SITE  search a site using Google
  --unfilter            do not omit similar results
  -p PROXY, --proxy PROXY
                        tunnel traffic through an HTTP proxy; PROXY is of the
                        form [http://][user:password@]proxyhost[:port]
  --noua                disable user agent
  --notweak             disable TCP optimizations and forced TLS 1.2
  --json                output in JSON format; implies --noprompt
  --url-handler UTIL    custom script or cli utility to open results
  --show-browser-logs   do not suppress browser output (stdout and stderr)
  --np, --noprompt      search and exit, do not prompt
  -u, --upgrade         perform in-place self-upgrade
  --include-git         when used with --upgrade, upgrade to latest git master
  -v, --version         show program's version number and exit
  -d, --debug           enable debugging

omniprompt keys:
  n, p                  fetch the next or previous set of search results
  index                 open the result corresponding to index in browser
  f                     jump to the first page
  o [index|range|a ...] open space-separated result indices, numeric ranges
                        (sitelinks unsupported in ranges), or all, in browser
                        open the current search in browser, if no arguments
  O [index|range|a ...] like key 'o', but try to open in a GUI browser
  g keywords            new Google search for 'keywords' with original options
                        should be used to search omniprompt keys and indices
  c index               copy url to clipboard
  u                     toggle url expansion
  q, ^D, double Enter   exit googler
  ?                     show omniprompt help
  *                     other inputs issue a new search with original options
```

#### Configuration file

`googler` doesn't have any! This is to retain the speed of the utility and avoid OS-specific differences. Users can enjoy the advantages of config files using aliases (with the exception of the color scheme, which can be additionally customized through an environment variable; see [Colors](#colors)). There's no need to memorize options.

For example, the following alias for bash/zsh/ksh/etc.

    alias g='googler -n 7 -c ru -l ru'

fetches 7 results from the Google Russia server, with preference towards results in Russian.

The alias serves both the purposes of using config files:

- Persistent settings: when the user invokes `g`, it expands to the preferred settings.
- Override settings: thanks to the way Python `argparse` works, `googler` is written so that the settings in alias are completely overridden by any options passed from cli. So when the same user runs `g -l de -c de -n 12 hello world`, 12 results are returned from the Google Germany server, with preference towards results in German.

#### googler @t

`googler @t` is a convenient add-on to Google Site Search with unique keywords. While `googler` has an integrated option to search a site, we simplified it further with aliases. The file [googler_at](https://github.com/jarun/googler/blob/master/auto-completion/googler_at/googler_at) contains a list of website search aliases. To source it, run:

    $ source googler_at
or,

    $ . googler_at
With `googler @t`, here's how you search Wikipedia for `hexspeak`:

    $ @w hexspeak
Oh yes! You can combine other `googler` options too! To make life easier, you can also configure your shell to source the file when it starts.

All the aliases start with the `@` symbol (hence the name `googler @t`) and there is minimum chance they will conflict with any shell commands. Feel free to add your own aliases to the file and contribute back the interesting ones.

#### Text-based browser integration

`googler` works out of the box with several text-based browsers if the `BROWSER` environment variable is set. For instance,

    $ export BROWSER=w3m

or for one-time use,

    $ BROWSER=w3m googler query

Due to certain graphical browsers spewing messages to the console, `googler` suppresses browser output by default unless `BROWSER` is set to one of the known text-based browsers: currently `elinks`, `links`, `lynx`, `w3m` or `www-browser`. If you use a different text-based browser, you will need to explicitly enable browser output with the `--show-browser-logs` option. If you believe your browser is popular enough, please submit an issue or pull request and we will consider whitelisting it. See the man page for more details on `--show-browser-logs`.

If you need to use a GUI browser with `BROWSER` set, use the omniprompt key `O`. `googler` will try to ignore text-based browsers and invoke a GUI browser. Browser logs are always suppressed with `O`.

#### Terminal Reading Mode or Reader View

You can easily integrate `googler` with some equally awesome utilities to enjoy your daily dose of news in a completely distraction-free environment. Read more [in the wiki](https://github.com/jarun/googler/wiki/Terminal-Reading-Mode-or-Reader-View).

#### Colors

`googler` allows you to customize the color scheme via a six-letter string, reminiscent of BSD `LSCOLORS`. The six letters represent the colors of

- indices
- titles
- URLs
- metadata/publishing info (Google News only)
- abstracts
- prompts

respectively. The six-letter string is passed in either as the argument to the `--colors` option, or as the value of the environment variable `GOOGLER_COLORS`.

We offer the following colors/styles:

Letter | Color/Style
------ | -----------
a      | black
b      | red
c      | green
d      | yellow
e      | blue
f      | magenta
g      | cyan
h      | white
i      | bright black
j      | bright red
k      | bright green
l      | bright yellow
m      | bright blue
n      | bright magenta
o      | bright cyan
p      | bright white
A-H    | bold version of the lowercase-letter color
I-P    | bold version of the lowercase-letter bright color
x      | normal
X      | bold
y      | reverse video
Y      | bold reverse video

The default colors string is `GKlgxy`, which stands for

- bold bright cyan indices
- bold bright green titles
- bright yellow URLs
- cyan metadata/publishing info
- normal abstracts
- reverse video prompts

Note that

- Bright colors (implemented as `\x1b[90m`–`\x1b[97m`) may not be available in all color-capable terminal emulators;
- Some terminal emulators draw bold text in bright colors instead;
- Some terminal emulators only distinguish between bold and bright colors via a default-off switch.

Please consult the manual of your terminal emulator as well as the [Wikipedia article](https://en.wikipedia.org/wiki/ANSI_escape_code) on ANSI escape sequences.

#### Domain-only URL

To show the domain names in search results instead of the expanded URL (and use lesser space), set the environment variable `DISABLE_URL_EXPANSION`.

### Examples

1. Google **hello world**:

       $ googler hello world

2. Fetch **15 results** updated within the last **14 months**, starting from the **3<sup>rd</sup> result** for the keywords **jungle book** in **site** imdb.com:

       $ googler -n 15 -s 3 -t m14 -w imdb.com jungle book

3. Read recent **news** on gadgets:

       $ googler -N gadgets

4. Fetch results on IPL cricket from **Google India** server in **English**:

       $ googler -c in -l en IPL cricket

5. Search **quoted text**:

       $ googler it\'s a \"beautiful world\" in spring

6. Search for a **specific file type**:

       $ googler instrumental filetype:mp3

7. Disable **automatic spelling correction**, e.g. fetch results for `googler` instead of `google`:

       $ googler -x googler

8. **I'm feeling lucky** search:

       $ googler -j leather jackets

9. **Website specific** search:

       $ googler -w amazon.com -w ebay.com digital camera
    Site specific search continues at omniprompt.

10. Alias to find **definitions of words**:

        alias define='googler -n 2 define'

11. Look up `n`, `p`, `o`, `O`, `q`, `g keywords` or a result index at the **omniprompt**: as the omniprompt recognizes these keys or index strings as commands, you need to prefix them with `g`, e.g.,

        g n
        g g keywords
        g 1

12. Input and output **redirection**:

        $ googler -C hello world < input > output
    Note that `-C` is required to avoid printing control characters (for colored output).

13. **Pipe** output:

        $ googler -C hello world | tee output

14. Use a **custom color scheme**, e.g., a warm color scheme designed for Solarized Dark ([screenshot](https://i.imgur.com/6L8VlfS.png)):

        $ googler --colors bjdxxy google
        $ GOOGLER_COLORS=bjdxxy googler google

15. Tunnel traffic through an **HTTPS proxy**, e.g., a local Privoxy instance listening on port 8118:

        $ googler --proxy localhost:8118 google
    By default the environment variable `https_proxy` is used, if defined.

16. Quote multiple search keywords to auto-complete (using completion script):

        $ googler 'hello w<TAB>

17. More **help**:

        $ googler -h
        $ man googler

### Troubleshooting

1. In some instances `googler` may show fewer number of results than you expect, e.g., if you fetch a single result (`-n 1`) it may not show any results. The reason is Google shows some Google service (e.g. Youtube) results, map locations etc. depending on your geographical data, which `googler` tries to omit. In some cases Google (the web-service) doesn't show exactly 10 results (default) on a search. We chose to omit these results as far as possible. While this can be fixed, it would need more processing (and more time). You can just navigate forward to fetch the next set of results.

2. By default `googler` applies some TCP optimizations and forces TLS 1.2 (on Python 3.4 and above). If you are facing connection issues, try disabling both using the `--notweak` switch.

3. Google News service is not available if the language is `dk` (Denmark), `fi` (Finland) or `is` (Iceland). Use `-l en`. Please refer to #187 for more information.

4. Some users have reported problems with a colored omniprompt (refer to issue [#203](https://github.com/jarun/googler/issues/203)) with iTerm2 on OS X. To force a plain omniprompt:

       export DISABLE_PROMPT_COLOR=1

### Notes

1. Initially I raised a pull request but I could see that the last change was made 7 years earlier. In addition, there is no GitHub activity from the original author [Henri Hakkinen](https://github.com/henux) in past year. I have created this independent repo for the project with the name `googler`. I retained the original copyright information.

2. Google provides a search API which returns the results in JSON format. However, as per my understanding from the [official docs](https://developers.google.com/custom-search/json-api/v1/overview), the API issues the queries against an existing instance of a custom search engine and is limited by 100 search queries per day for free. In addition, I have reservations in paying if they ever change their plan or restrict the API in other ways. So I refrained from coupling with Google plans & policies or exposing my trackable personal custom search API key and identifier for the public. I retained the browser-way of doing it by fetching html, which is a open and free specification.

3. You can find a rofi script for `googler` [here](http://hastebin.com/fonowacija.bash). Written by an anonymous user, untested and we don't maintain it.

### Contributions

Pull requests are welcome. Please visit [#209](https://github.com/jarun/googler/issues/209) for a list of TODOs.
<br>
<p><a href="https://gitter.im/jarun/googler"><img src="https://img.shields.io/gitter/room/jarun/googler.svg?maxAge=2592000" alt="gitter chat" /></a></p>

### Developers

1. Copyright © 2008 Henri Hakkinen
2. Copyright © 2015-2018 [Arun Prakash Jana](https://github.com/jarun)
3. [Zhiming Wang](https://github.com/zmwangx)
4. [Johnathan Jenkins](https://github.com/shaggytwodope)
5. [SZ Lin](https://github.com/szlin)

Special thanks to [jeremija](https://github.com/jeremija) and [Narrat](https://github.com/Narrat) for their contributions.

### Logo

Logo copyright © 2017 Zhiming Wang.

You may freely redistribute it alongside the code, or use it when describing or linking to this project. You should NOT create modified versions of it, make it the logo or icon of your project (except personal forks and/or forks with the goal of upstreaming), or otherwise use it without written permission.
