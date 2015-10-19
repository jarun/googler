# google-cli Makefile

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
MANDIR=$(PREFIX)/share/man/man1
DOCDIR=$(PREFIX)/share/doc/google-cli
UNAME_S:=$(shell uname -s)


.PHONY: install uninstall

install:
	install -m755 -d $(BINDIR)
	install -m755 -d $(MANDIR)
	install -m755 -d $(DOCDIR)
	gzip -c googler.1 > googler.1.gz
	@if [ "$(UNAME_S)" = "Linux" ]; then\
		install -m755 -t $(BINDIR) googler; \
		install -m644 -t $(MANDIR) googler.1.gz; \
		install -m644 -t $(DOCDIR) README.md; \
	fi
	@if [ "$(UNAME_S)" = "Darwin" ]; then\
		install -m755  googler $(BINDIR); \
		install -m644  googler.1.gz $(MANDIR); \
		install -m644  README.md $(DOCDIR); \
	fi
	rm -f googler.1.gz

uninstall:
	rm -f $(BINDIR)/googler
	rm -f $(MANDIR)/googler.1.gz
	rm -rf $(DOCDIR)
