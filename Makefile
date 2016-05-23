PREFIX ?= /usr/local
BINDIR = $(DESTDIR)$(PREFIX)/bin
MANDIR = $(DESTDIR)$(PREFIX)/share/man/man1
DOCDIR = $(DESTDIR)$(PREFIX)/share/doc/googler
BASHCOMPDIR = $(DESTDIR)$(PREFIX)/etc/bash_completion.d
FISHCOMPDIR = $(DESTDIR)$(PREFIX)/share/fish/vendor_completions.d
ZSHCOMPDIR = $(DESTDIR)$(PREFIX)/share/zsh/site-functions

.PHONY: all install install.comp uninstall uninstall.comp

all:

install:
	install -m755 -d $(BINDIR)
	install -m755 -d $(MANDIR)
	install -m755 -d $(DOCDIR)
	gzip -c googler.1 > googler.1.gz
	install -m755 googler $(BINDIR)
	install -m644 googler.1.gz $(MANDIR)
	install -m644 README.md $(DOCDIR)
	rm -f googler.1.gz

install.comp:
	install -m755 -d $(BASHCOMPDIR) $(FISHCOMPDIR) $(ZSHCOMPDIR)
	install -m644 auto-completion/bash/googler-completion.bash $(BASHCOMPDIR)
	install -m644 auto-completion/fish/googler.fish $(FISHCOMPDIR)
	install -m644 auto-completion/zsh/_googler $(ZSHCOMPDIR)

uninstall:
	rm -f $(BINDIR)/googler
	rm -f $(MANDIR)/googler.1.gz
	rm -rf $(DOCDIR)

uninstall.comp:
	rm -f $(BASHCOMPDIR)/googler-completion.bash $(FISHCOMPDIR)/googler.fish $(ZSHCOMPDIR)/_googler
