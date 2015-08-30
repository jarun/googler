# google-cli

![Screenshot](google-cli.png)

Copyright (C) 2008 Henri Hakkinen

Modified (2015) by Arun Prakash Jana &lt;engineerarun@gmail.com&gt;

`google` is a command line tool for doing Google searches from the terminal. For each result it shows the header, URL and text context. You can also navigate back and forth to fetch the next or previous results. On link-recognising terminal emulators like AltYo, use `Ctrl-Left click` to open the URL in your default browser. For features, check usage below.

<pre>Usage: google [OPTIONS] KEYWORDS...  
Options  
    -s N     start at the N<sup>th</sup> result  
    -n N     shows N results (default 10)  
    -c SERV  country-specific search (Ref: https://en.wikipedia.org/wiki/List_of_Google_domains)  
             Added TLDs: ar, au, be, br, ca, ch, cz, de,  
             es, fi, fr, id, in, it, jp, kr, mx, nl, ph,  
             pl, pt, ro, ru, se, tw, ua, uk  
    -l LANG  display in language LANG, such as fi for Finnish  
    -C       disable color output  
    -j       open the first result in a web browser  
    -f MIME  search for specific file type  
    -t dN    time limit search [e.g. d5: 5 days, w5: 5 weeks, m5: 5 months, y5: 5 years]

Keys
    n, p     press 'n' or 'p' and Enter to navigate forward and backward
    1-N      press a number and Enter to open that result in browser</pre>  

Examples:

1. Google <b>hello world</b>:
<pre>$ google hello world</pre>
2. To fetch 15 results updated within last 2 months, starting from the 3<sup>rd</sup> result for the string <b>cmdline utility</b> in site tuxdiary.com, run:
<pre>$ google -n 15 -s 3 -t m2 cmdline utility site:tuxdiary.com</pre>

Report bugs to https://github.com/jarun/google-cli/issues

See the manual page for full details.  Have fun!

# Installation

google-cli requires Python 2.7.x or Python 3.x to work.

The following steps are tested on Ubuntu 14.04.3 x64_64:  
<pre>$ git clone https://github.com/jarun/google-cli/  
$ cd google-cli  
$ sudo make install</pre>  

To remove, run:  
<pre>$ sudo make uninstall</pre>

# News

>**28 Aug, 2015**
> - Support country-specific search (Open to additions on request)

>**27 Aug, 2015**
> - Time limit search by hours

>**26 Aug, 2015**
> - Open result in browser using index number (thanks jeremija) 
> - Convert %22 to " (double quote) in URLs
> - Inputs other than n, p or number (+ Enter) exit

>**25 Aug, 2015**
> - Add Python 3.x support (thanks Narrat)
> - Add UTF-8 request and response (thanks Narrat)

>**22 Aug, 2015**
> - Add navigation support

>**17 Aug, 2015**
> - Support for time limited search  
> - Throw error in case of google error due to unusual activity from IP  
> - Support file type in search

>**16 Aug, 2015**
> - Use https  
> - Handle google redirections (error 302)
> - Show full text snippet of search results
> - Unicode in URL works
> - Colour output by default, -C now disables it (toggled)
> - The first URL now correctly opens in browser with -j switch
> - Honour -j even if -n is not used and open the result in browser
> - Fixed character encoding problem in URL e.g. double quotes (%22) changed to %2522
> - Skip browser to show result in console for empty URL, e.g., first result of ‘define hello’


# Note

Initially I raised a pull request but I could see that the last change was made 7 years earlier. In addition, there is no GitHub activity from the original author (Henri Hakkinen: https://github.com/henux ) in past year. I have created this independent repo for the project with the name google-cli. Would love to push the changes back to original repo if the author contacts. I retained the original copyright information.
