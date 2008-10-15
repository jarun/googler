# cli-google Makefile

DESTDIR=/usr/local
BINDIR=$(DESTDIR)/bin
MANDIR=$(DESTDIR)/share/man/man1
DOCDIR=$(DESTDIR)/share/doc/cli-google

.PHONY: install uninstall

install:
	install -D -m755 google $(BINDIR)/google
	install -D -m644 google.1 $(MANDIR)/google.1
	install -D -m644 ChangeLog $(DOCDIR)/ChangeLog
	install -D -m644 README $(DOCDIR)/README

uninstall:
	rm -rf $(BINDIR)/google
	rm -rf $(MANDIR)/google.1
	rm -rf $(DOCDIR)/ChangeLog
	rm -rf $(DOCDIR)/README
