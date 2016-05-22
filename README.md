<h1 align="center">googler</h1>

<p align="center">
<a href="https://aur.archlinux.org/packages/googler"><img src="https://img.shields.io/aur/version/googler.svg" alt="AUR" /></a>
<a href="http://braumeister.org/formula/googler"><img src="https://img.shields.io/homebrew/v/googler.svg" alt="Homebrew" /></a>
<a href="https://github.com/jarun/googler/releases/latest"><img src="https://img.shields.io/github/release/jarun/googler.svg" alt="Latest release" /></a>
<a href="https://travis-ci.org/jarun/googler"><img src="https://travis-ci.org/jarun/googler.svg?branch=master" alt="Build Status" /></a>
<a href="https://github.com/jarun/googler/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-yellow.svg?maxAge=2592000" alt="License" /></a>
</p>

<p align="center">
<a href="https://asciinema.org/a/46340"><img src="https://asciinema.org/a/46340.png" alt="Asciicast" width="734"/></a>
</p>

`googler` is a power tool to Google (Web & News) and Google Site Search from the terminal. It shows the title, URL and text context for each result, which can be directly opened in a browser from the terminal. Results are fetched in pages (with page navigation). Supports sequential searches in a single `googler` instance.

`googler` isn't affiliated to Google in any way.

Got some suggestions? [![gitter chat](https://img.shields.io/gitter/room/jarun/googler.svg?maxAge=2592000)](https://gitter.im/jarun/googler) with us.

Find `googler` useful? If you would like to donate, visit the
[![Donate Button](https://img.shields.io/badge/paypal-donate-orange.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RMLTQ76JSXJ4Q) page.

# Table of contents

- [Features](#features)
- [Installation](#installation)
    - [Installing from this repository](#installing-from-this-repository)
        - [Installing to default or custom location](#installing-to-default-or-custom-location)
        - [Running as a standalone utility](#running-as-a-standalone-utility)
        - [Shell completion](#shell-completion)
    - [Installing with a package manager](#installing-with-a-package-manager)
    - [Debian package](#debian-package)
- [Usage](#usage)
    - [Cmdline options](#cmdline-options)
    - [Configuration file](#configuration-file)
    - [Colors](#colors)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Developers](#developers)
- [Notes](#notes)

# Features

- Google Search, Google Site Search, Google News
- Fast and clean (no ads, stray URLs or clutter), custom color
- Open result URLs (or the actual search) in browser
- Navigate search result pages from omniprompt
- Fetch n results in a go, start at the n<sup>th</sup> result
- Disable automatic spelling correction and search exact keywords
- Limit search by duration, country/domain specific search (default: .com), language preference
- Supports Google search keywords like `filetype:mime`, `site:somesite.com` etc.
- Optionally open the first result directly in browser (as in *I'm Feeling Lucky*)
- Non-stop searches: fire new searches at omniprompt without exiting
- Man page with examples, shell completion scripts for Bash, Zsh and Fish
- Minimal dependencies

# Installation

`googler` requires Python 3.3 or later to work. Only the latest patch release of each minor version is supported.

Python 2.x support has been deprecated from `googler v2.4.1`.

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

### Shell completion

Shell completion scripts for Bash, Fish and Zsh can be found in respective subdirectories of [`auto-completion/`](auto-completion). Please refer to your shell's manual for installation instructions.

## Installing with a package manager

`googler` is also available on

- [AUR](https://aur.archlinux.org/packages/googler/) for Arch Linux;
- [Fossies](http://fossies.org/linux/googler);
- [Homebrew](http://braumeister.org/formula/googler) for OS X, or its Linux fork, [Linuxbrew](https://github.com/Linuxbrew/linuxbrew/blob/master/Library/Formula/googler.rb).

## Debian package

If you are on a Debian (including Ubuntu) based system visit [the latest stable release](https://github.com/jarun/googler/releases/latest) and download the`.deb`package. To install, run:

    $ sudo dpkg -i googler-$version-all.deb

Please substitute `$version` with the appropriate package version.

# Usage

## Cmdline options

    usage: googler [-s N] [-n N] [-N] [-c TLD] [-l LANG] [-x] [-C] [-j] [-t dN]
                   [-w SITE] [-d]
                   KEYWORD [KEYWORD ...]

    Google from the command-line.

    positional arguments:
      KEYWORD               search keywords

    optional arguments:
      -s N, --start N       start at the Nth result
      -n N, --count N       show N results (default 10)
      -N, --news            show results from news section
      -c TLD, --tld TLD     country-specific search with top-level domain .TLD,
                            e.g., 'in' for India. Ref:
                            https://en.wikipedia.org/wiki/List_of_Google_domains
      -l LANG, --lang LANG  display in language LANG
      -x, --exact           disable automatic spelling correction
      -C, --nocolor         disable color output
      --colors COLORS       set output colors (see man page for details)
      -j, --first, --lucky  open the first result in a web browser
      -t dN, --time dN      time limit search [h5 (5 hrs), d5 (5 days), w5 (5
                            weeks), m5 (5 months), y5 (5 years)]
      -w SITE, --site SITE  search a site using Google
      --json                output in JSON format; implies --noprompt
      --np, --noprompt      perform search and exit, do not prompt for further
                            interactions
      -d, --debug           enable debugging

    omniprompt keys:
      n, p                  fetch the next or previous set of search results
      index                 open the result corresponding to index in browser
      f                     jump to the first page
      o                     open the current search in browser
      g keywords            initiate a new Google search for 'keywords' with original options
      q, ^D, double Enter   exit googler
      ?                     show omniprompt help
      *                     any other string initiates a new search with original options

## Configuration file

`googler` doesn't have any! This is to retain the speed of the utility and avoid OS-specific differences. Users can enjoy the advantages of config files using aliases (with the exception of the color scheme, which can be additionally customized through an environment variable; see [Colors](#colors)). There's no need to memorize options.

For example, the following alias for bash/zsh/ksh/etc.

    alias g='googler -n 7 -c ru -l ru'

fetches 7 results from the Google Russia server, with preference towards results in Russian.

The alias serves both the purposes of using config files:

- Persistent settings: when the user invokes `g`, it expands to the preferred settings.
- Override settings: thanks to the way Python `argparse` works, `googler` is written so that the settings in alias are completely overridden by any options passed from cli. So when the same user runs `g -l de -c de -n 12 hello world`, 12 results are returned from the Google Germany server, with preference towards results in German.

## Colors

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

The default colors string is `GKlxxy`, which stands for

- bold bright cyan indices
- bold bright green titles
- bright yellow URLs
- normal metadata/publishing info
- normal abstracts
- reverse video prompts

Note that

- Bright colors (implemented as `\x1b[90m`–`\x1b[97m`) may not be available in all color-capable terminal emulators;
- Some terminal emulators draw bold text in bright colors instead;
- Some terminal emulators only distinguish between bold and bright colors via a default-off switch.

Please consult the manual of your terminal emulator as well as the [Wikipedia article](https://en.wikipedia.org/wiki/ANSI_escape_code) on ANSI escape sequences.

# Examples

1. Google **hello world**:

        $ googler hello world

2. Fetch **15 results** updated within last **14 months**, starting from the **3<sup>rd</sup> result** for the string **cmdline utility** in **site** tuxdiary.com:

        $ googler -n 15 -s 3 -t m14 -w tuxdiary.com cmdline utility

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

9. **Website specific** search:

        $ googler -w tuxdiary.com hello world
Site specific search continues at omniprompt. Use the `g` key to run a regular Google search.
10. Alias to find **definitions of words**:

        alias define='googler -n 2 define'

11. Look up `n`, `p`, `o`, `q`, `g keywords` or a result index at the **omniprompt**: As the omniprompt recognizes `n`, `p`, `o`, `q`, `g` or index strings as commands, you need to prefix them with `g`, e.g.,

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

15. More **help**:

        $ googler
        $ man googler

# Troubleshooting

1. In some instances `googler` may show fewer number of results than you expect, e.g., if you fetch a single result (`-n 1`) it may not show any results. The reason is Google shows some Google service (e.g. Youtube) results, map locations etc. depending on your geographical data, which `googler` tries to omit. In some cases Google (the web-service) doesn't show exactly 10 results (default) on a search. We chose to omit these results as far as possible. While this can be fixed, it would need more processing (and more time). You can just navigate forward to fetch the next set of results.

# Developers

1. Copyright (C) 2008 Henri Hakkinen
2. Copyright (C) 2015-2016 [Arun Prakash Jana](mailto:engineerarun@gmail.com)
3. [Zhiming Wang](https://github.com/zmwangx)

Special thanks to [jeremija](https://github.com/jeremija), [shaggytwodope](https://github.com/shaggytwodope) and [Narrat](https://github.com/Narrat) for their contributions and efforts in spreading `googler`.

# Notes

1. Initially I raised a pull request but I could see that the last change was made 7 years earlier. In addition, there is no GitHub activity from the original author [Henri Hakkinen](https://github.com/henux) in past year. I have created this independent repo for the project with the name `googler`. I retained the original copyright information.

2. Google provides a search API which returns the results in JSON format. However, as per my understanding from the [official docs](https://developers.google.com/custom-search/json-api/v1/overview), the API issues the queries against an existing instance of a custom search engine and is limited by 100 search queries per day for free. In addition, I have reservations in paying if they ever change their plan or restrict the API in other ways. So I refrained from coupling with Google plans & policies or exposing my trackable personal custom search API key and identifier for the public. I retained the browser-way of doing it by fetching html, which is a open and free specification.
