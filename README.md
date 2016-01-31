# google-cli

![Screenshot](google-cli.png)

`google-cli` is a command-line power tool to search Google (Web & News) from the terminal. It shows the title, URL and text context for each result. Results are fetched in pages. Next or previous page navigation is possible using keyboard shortcuts. Results are indexed and a result URL can be opened in a browser using the index number. Supports sequential searches in a single instance.
  
`google-cli` is GPLv3 licensed. It doesn't have any affiliation to Google in any way.  
  
Why not use Google provided APIs? Check point 2 in [Notes](#Notes).

If you find `google-cli` useful, please consider donating via PayPal.  
<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=RMLTQ76JSXJ4Q"><img src="https://www.paypal.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate Button with Credit Cards" /></a>

# Features

- Uses HTTPS connection
- Fetch n results in a go
- Start at n<sup>th</sup> result
- Fetch and navigate next or previous set of results
- Initiate a new search with original options (in a single instance)
- Reconnect on new search even if connection is closed due to inactivity
- Easily open result URLs in browser from cmdline using index number
- Browser (Chromium and Firefox based) errors and warnings suppression
- Show full contextual text snippet in search results
- Specify search duration (in hours / days / weeks / months / years)
- Fetch results from Google News section
- Country/domain specific search (28 top-level domains supported, default: .com)
- Google search keywords like `filetype:mime`, `site:somesite.com` etc. work.
- Open filetype specific links in browser, the links are handled by browser for the type
- Optionally open the first result directly in browser (as in <i>I'm Feeling Lucky</i>)
- Specify language preference for results
- Handle first level of Google redirections (reports IP blocking by Google)
- Unicode in URL works
- Skip links to Google News, Images or blank URLs in web search results
- UTF-8 request and response
- Fetch gzip compressed results
- Works with Python 2.7.x and 3.x
- Enable/disable color output (default: colorful)
- Enable/disable debug logs (default: disabled)
- Manpage for quick reference
- Fast and clean (no ads or clutter)
- Minimal dependencies
- Open source and free

# Installation

`google-cli` requires Python 2.7.x or Python 3.x to work.

1. If you have git installed (the steps are tested on Ubuntu 14.04.3 x64_64):  
<pre>$ git clone https://github.com/jarun/google-cli/  
$ cd google-cli  
$ sudo make install</pre>  
To remove, run:  
<pre>$ sudo make uninstall</pre>

2. If you do not have git installed:  
Download the latest <a href="https://github.com/jarun/google-cli/releases/latest">stable release</a> or <a href="https://github.com/jarun/google-cli/archive/master.zip">development version</a> source code. Extract, cd into the directory and run:
<pre>$ sudo make install</pre>
If you do not want to install, `googler` is standalone:
<pre>$ chmod +x googler
$ ./googler ...</pre>

3. `google-cli` is also available on <a href="https://aur.archlinux.org/packages/google-cli/">AUR</a> and <a href="http://fossies.org/linux/google-cli">Fossies</a>.

# Usage

<pre>Usage: googler [OPTIONS] KEYWORDS...
Options
    -s N     start at the N<sup>th</sup> result
    -n N     show N results (default 10)
    -N       show results from news section
    -c SERV  country-specific search (Ref: https://en.wikipedia.org/wiki/List_of_Google_domains)
             Added TLDs: ar, au, be, br, ca, ch, cz, de,
             es, fi, fr, id, in, it, jp, kr, mx, nl, ph,
             pl, pt, ro, ru, se, tw, ua, uk
    -l LANG  display in language LANG, such as fi for Finnish
    -C       disable color output
    -j       open the first result in a web browser
    -t dN    time limit search [h5 (5 hrs), d5 (5 days), w5 (5 weeks), m5 (5 months), y5 (5 years)]
    -d       enable debugging

Keys
    g terms  enter 'g' followed by keywords to initiate a new search (with original options)
    n, p     enter 'n' or 'p' to navigate forward or backward
    1-N      enter a number to open that result in browser
             any other input exits googler</pre>

<b>Configuration file</b>  
  
`google-cli` doesn't have any! This is to retain the speed of the utlity and avoid OS-specific differences. Users can enjoy the advantage of config files using aliases. There's no need to memorize options.  
  
For example, the following alias set in `~/.bashrc`:
<pre>alias g='googler -n 7 -c ru -l ru'</pre>
fetches 7 results from the Google Russia server, with preference towards results in Russian.  
  
The alias serves both the purposes of using config files:
- persistent settings: when the user invokes `g`, it expands to the preferred settings everytime.
- override settings: thanks to the way Python getopt() works, `google-cli` is written so that the settings in alias are completely overridden by any options passed from cli. So when the same user runs:  
<code>$ g -l de -c de -n 12 hello world</code>  
12 results are returned from the Google Germany server, with preference towards results in German.
  
Windows users can refer the following discussion on how to use aliases on Windows:
http://stackoverflow.com/questions/20530996/aliases-in-windows-command-prompt

# Examples

1. Google <b>hello world</b>:
<pre>$ googler hello world</pre>
2. To fetch <b>15 results</b> updated within last <b>14 months</b>, starting from the <b>3<sup>rd</sup> result</b> for the string <b>cmdline utility</b> in <b>site</b> tuxdiary.com, run:
<pre>$ googler -n 15 -s 3 -t m14 cmdline utility site:tuxdiary.com</pre>
3. Read recent <b>news</b> on gadgets:
<pre>$ googler -N gadgets</pre>
4. Fetch results on IPL cricket from <b>Google India</b> server in <b>English</b>:
<pre>$ googler -c in -l en IPL cricket</pre> 
5. Search quoted text e.g. <b>it's a "beautiful world" in spring</b>:
<pre>$ googler it\'s a \"beautiful world\" in spring</pre>
6. Search for a <b>specific file type</b>:
<pre>$ googler instrumental filetype:mp3</pre>
7. <b>I'm feeling lucky</b> search:
<pre>$ googler -j leather jackets</pre>
8. <b>Website specific</b> search alias:
<pre>alias t='googler -n 7 site:tuxdiary.com'</pre>
9. Alias to find <b>meanings of words</b> (note: the first result in Google is not a link):
<pre>alias define='googler -n 2 define'</pre>
10. On the fly <b>help</b> (usage details):
<pre>$ googler</pre>
11. Input and output <b>redirection</b>:
<pre>$ googler -C hello world < input > output</pre>
Note that `-C` is required to avoid printing control characters. `2>&1` would error as the console geometry is calculated from `stderr`.
12. <b>Piping</b> `google-cli` output:
<pre>$ googler -C hello world | tee output</pre>

# Developers

Copyright (C) 2008 Henri Hakkinen

Modified (2015) by Arun Prakash Jana &lt;engineerarun@gmail.com&gt;

<h1 id="Notes">Notes</h1>

1. Initially I raised a pull request but I could see that the last change was made 7 years earlier. In addition, there is no GitHub activity from the original author [Henri Hakkinen](https://github.com/henux) in past year. I have created this independent repo for the project with the name `google-cli`. Would love to push the changes back to original repo if the author contacts. I retained the original copyright information.
2. Google provides a search API which returns the results in JSON format. However, as per my understanding from the [official docs](https://developers.google.com/custom-search/json-api/v1/overview), the API issues the queries against an existing instance of a custom search engine and is limited by 100 search queries per day for free. In addition, I have reservations in paying if they ever change their plan or restrict the API in other ways. So I refrained from coupling with Google plans & policies or exposing my trackable personal custom search API key and identifier for the public. I retained the browser-way of doing it by fetching html, which is a open and free specification.
