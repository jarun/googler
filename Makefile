# cli-google Makefile

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
MANDIR=$(PREFIX)/share/man/man1
DOCDIR=$(PREFIX)/share/doc/cli-google

.PHONY: install uninstall

install:
	install -m755 -d $(BINDIR)
	install -m755 -d $(MANDIR)
	install -m755 -d $(DOCDIR)
	gzip -c google.1 > google.1.gz
	install -m755 -t $(BINDIR) google
	install -m644 -t $(MANDIR) google.1.gz
	install -m644 -t $(DOCDIR) README.md
	rm -f google.1.gz

uninstall:
	rm -f $(BINDIR)/google
	rm -f $(MANDIR)/google.1.gz
	rm -rf $(DOCDIR)
