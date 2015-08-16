# google-cli
  
![Screenshot](google-cli.png)
  
Copyright (C) 2008 Henri Hakkinen

Modified (2015) by Arun Prakash Jana <engineerarun@gmail.com>

`google` is a command line tool for doing Google searches from the
terminal.  To install the package to your system, run `make install` as
root.

<pre>Usage: google [OPTIONS] KEYWORDS...  
Options  
    -s N     start at the Nth result  
    -n N     shows N results  
    -l LANG  display in language LANG, such as fi for Finnish  
    -C       disable color output  
    -j       open the first result in a web browser  
    -t dN    time limit search [e.g. d5: 5 days, w5: 5 weeks, m5: 5 months, y5: 5 years]</pre>  

Report bugs to https://github.com/jarun/google-cli/issues

See the manual page for full details.  Have fun!

# Installation

The following steps are tested on Ubuntu 14.04.3 x64_64:  
<pre>$ git clone https://github.com/jarun/google-cli/  
$ cd google-cli  
$ sudo make install</pre>  
  
To remove, run:  
<pre>$ sudo make uninstall</pre>

# News
  
>**17 Aug, 2015**
> - Support for time limited search  
> - Throw error in case of google error due to unusual activity from IP
  
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
