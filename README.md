# googler

![Screenshot](http://i.imgur.com/DlXq7MI.png)

`googler` is a command-line power tool to search Google (Web & News) from the terminal. It shows the title, URL and text context for each result. Results are fetched in pages. Next or previous page navigation is possible using keyboard shortcuts. Results are indexed and a result URL can be opened in a browser using the index number. Supports sequential searches in a single instance.

`googler` is **GPLv3** licensed. It doesn't have any affiliation to Google in any way.

Why not use Google provided APIs? Check point 2 in [Notes](#notes) section.

If you find `googler` useful, please consider donating via PayPal.
[![Donate Button](https://www.paypal.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RMLTQ76JSXJ4Q)

# Table of contents

- [Features](#features)
- [Installation](#installation)
    - [Installing from this repository](#installing-from-this-repository)
        - [Installing to default or custom location](#installing-to-default-or-custom-location)
        - [Running as a standalone utility](#running-as-a-standalone-utility)
    - [Installing with a package manager](#installing-with-a-package-manager)
- [Usage](#usage)
    - [Configuration file](#configuration-file)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Developers](#developers)
- [Notes](#notes)

# Features

- Uses HTTPS connection
- Fetch n results in a go
- Start at n<sup>th</sup> result
- Fetch and navigate next or previous set of results
- Continuous search: fire new searches without exiting
- Reconnect on new search even if connection is closed due to inactivity
- Disable automatic spelling correction and search exact keywords (default: enabled)
- Easily open result URLs in browser from cmdline using index number
- Browser (Chromium and Firefox based) errors and warnings suppression
- Show full contextual text snippet in search results
- Specify search duration (in hours / days / weeks / months / years)
- Fetch results from Google News section
- Country/domain specific search (28 top-level domains supported, default: .com)
- Supports Google search keywords like `filetype:mime`, `site:somesite.com` etc.
- Open filetype specific links in browser, the links are handled by browser for the type
- Optionally open the first result directly in browser (as in <i>I'm Feeling Lucky</i>)
- Specify language preference for results
- Handle first level of Google redirections (reports IP blocking by Google)
- Unicode in URL works
- Skip links to Google News, Images or blank URLs in web search results
- UTF-8 request and response
- Fetch gzip compressed results
- Works with Python 2.7.x and 3.3.x or later
- Enable/disable color output (default: colorful)
- Enable/disable debug logs (default: disabled)
- Manpage for quick reference
- Fast and clean (no ads or clutter)
- Minimal dependencies
- Open source and free

# Installation

`googler` requires Python to work. Officially supported Python versions are 2.7 and 3.3 or later (only the latest patch release of each minor version is supported).

## Installing from this repository

To download this repository, you may either clone via git:

    $ git clone https://github.com/jarun/googler/

or download a source code archive: [the latest stable release](https://github.com/jarun/googler/releases/latest) or [the development version](https://github.com/jarun/googler/archive/master.zip).

### Installing to default or custom location

Run

    $ sudo make install

to install to `/usr/local`. To install to a different prefix, run

    $ PREFIX=/path/to/prefix make install

You may need to prepend `sudo` if the prefix is only writable by root.

To remove `googler` and associated docs, run

    $ sudo make uninstall

If you installed to a different prefix, you'll need to specify the same `PREFIX` as when you ran `make install`.

### Running as a standalone utility

`googler` is a standalone executable. From the containing directory:

    $ ./googler

## Installing with a package manager

`googler` is also available on

- [AUR](https://aur.archlinux.org/packages/googler/) for Arch Linux;
- [Fossies](http://fossies.org/linux/googler);
- [Homebrew](http://braumeister.org/formula/googler) for OS X, or its Linux fork, [Linuxbrew](https://github.com/Linuxbrew/linuxbrew/blob/master/Library/Formula/googler.rb).

# Usage

    $ googler
    Usage: googler [OPTIONS] KEYWORDS...
    Performs a Google search and prints the results to stdout.

    Options
        -s N     start at the N<sup>th</sup> result
        -n N     show N results (default 10)
        -N       show results from news section
        -c SERV  country-specific search (Ref: https://en.wikipedia.org/wiki/List_of_Google_domains)
                 Added TLDs: ar, au, be, br, ca, ch, cz, de,
                 es, fi, fr, id, in, it, jp, kr, mx, nl, ph,
                 pl, pt, ro, ru, se, tw, ua, uk
        -l LANG  display in language LANG, such as fi for Finnish
        -x       disable automatic spelling correction
        -C       disable color output
        -j       open the first result in a web browser
        -t dN    time limit search [h5 (5 hrs), d5 (5 days), w5 (5 weeks), m5 (5 months), y5 (5 years)]
        -d       enable debugging

    Prompt Keys
        g terms  initiate a new search for 'terms' with original options
        n, p     fetch next or previous set of search results
        1-N      open the Nth result index in browser
        Enter    exit googler (same behaviour for an empty search)
        *        any other string initiates a new search with original options

## Configuration file

`googler` doesn't have any! This is to retain the speed of the utlity and avoid OS-specific differences. Users can enjoy the advantage of config files using aliases. There's no need to memorize options.

For example, the following alias for bash/zsh/ksh/etc.

    alias g='googler -n 7 -c ru -l ru'

fetches 7 results from the Google Russia server, with preference towards results in Russian.

The alias serves both the purposes of using config files:

- Persistent settings: when the user invokes `g`, it expands to the preferred settings everytime.
- Override settings: thanks to the way Python `getopt()` works, `googler` is written so that the settings in alias are completely overridden by any options passed from cli. So when the same user runs `g -l de -c de -n 12 hello world`, 12 results are returned from the Google Germany server, with preference towards results in German.

Windows users can refer to [this discussion](http://stackoverflow.com/questions/20530996/aliases-in-windows-command-prompt) on how to use aliases on Windows.

# Examples

1. Google **hello world**:

        $ googler hello world

2. Fetch **15 results** updated within last **14 months**, starting from the **3<sup>rd</sup> result** for the string **cmdline utility** in **site** tuxdiary.com:

        $ googler -n 15 -s 3 -t m14 cmdline utility site:tuxdiary.com

3. Read recent **news** on gadgets:

        $ googler -N gadgets

4. Fetch results on IPL cricket from **Google India** server in **English**:

        $ googler -c in -l en IPL cricket

5. Search quoted text e.g. **it's a "beautiful world" in spring**:

        $ googler it\'s a \"beautiful world\" in spring

6. Search for a **specific file type**:

        $ googler instrumental filetype:mp3

7. Disable **automatic spelling correction**, e.g. fetch results for `googler` instead of `google`:

        $ googler -x googler

8. **I'm feeling lucky** search:

        $ googler -j leather jackets

9. **Website specific** search alias:

        alias t='googler -n 7 site:tuxdiary.com'

10. Alias to find **definitions of words**:

        alias define='googler -n 2 define'

11. Look up `n`, `p`, `g co` or a number at the **navigation prompt**: As the navigation prompt recognizes `n`, `p`, `g` or numbers as commands, you need to prefix them with `g`, e.g., `g n`, `g g keywords`, `g 1984`.

12. Input and output **redirection**:

        $ googler -C hello world < input > output

    Note that `-C` is required to avoid printing control characters (for colored output).

13. **Piping** `googler` output:

        $ googler -C hello world | tee output

14. More **help**:

        $ googler
        $ man googler

# Troubleshooting

1.  If `print()` throws the following error complaining about handling Unicode with `ascii` codec:

        UnicodeEncodeError: 'ascii' codec can't encode character '\u201c' in position 0: ordinal not in range(128)

    add the following to your shell's runcom (`rc`, `profile`, etc.):

        export PYTHONIOENCODING=UTF-8

    If you use fish shell, add the following to `~/.config/fish/config.fish`:

        set -x PYTHONIOENCODING UTF-8

    Ref issue [#21](https://github.com/jarun/googler/issues/21).

2. In some instances `googler` may show fewer number of results than you expect, e.g., if you fetch a single result (`-n 1`) it may not show any results. The reason is Google shows some Google service (e.g. Youtube) results, map locations etc. depending on your geographical data, which `googler` tries to omit. In some cases Google (the web-service) doesn't show exactly 10 results (default) on a search. We chose to omit these results as far as possible. While this can be fixed, it would need more processing (and more time). You can just navigate forward to fetch the next set of results.

# Developers

1. Copyright (C) 2008 Henri Hakkinen
2. Resurrected and maintained (2015 -) by [Arun Prakash Jana](mailto:engineerarun@gmail.com)
3. [Zhiming Wang](https://github.com/zmwangx)

Special thanks to [jeremija](https://github.com/jeremija), [shaggytwodope](https://github.com/shaggytwodope) and [Narrat](https://github.com/Narrat) for their contributions and efforts in spreading `googler`.

[![Build Status](https://travis-ci.org/jarun/googler.svg?branch=master)](https://travis-ci.org/jarun/googler)

# Notes

1. Initially I raised a pull request but I could see that the last change was made 7 years earlier. In addition, there is no GitHub activity from the original author [Henri Hakkinen](https://github.com/henux) in past year. I have created this independent repo for the project with the name `googler`. I retained the original copyright information.

2. Google provides a search API which returns the results in JSON format. However, as per my understanding from the [official docs](https://developers.google.com/custom-search/json-api/v1/overview), the API issues the queries against an existing instance of a custom search engine and is limited by 100 search queries per day for free. In addition, I have reservations in paying if they ever change their plan or restrict the API in other ways. So I refrained from coupling with Google plans & policies or exposing my trackable personal custom search API key and identifier for the public. I retained the browser-way of doing it by fetching html, which is a open and free specification.
