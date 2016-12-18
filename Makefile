PREFIX ?= /usr/local
BINDIR = $(DESTDIR)$(PREFIX)/bin
MANDIR = $(DESTDIR)$(PREFIX)/share/man/man1
DOCDIR = $(DESTDIR)$(PREFIX)/share/doc/googler

.PHONY: all install uninstall disable-self-upgrade

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

uninstall:
	rm -f $(BINDIR)/googler
	rm -f $(MANDIR)/googler.1.gz
	rm -rf $(DOCDIR)

# Disable the self-upgrade mechanism entirely. Intended for packagers.
#
# We assume that sed(1) has the -i option, which is not POSIX but seems common
# enough in modern implementations.
disable-self-upgrade:
	sed -i.bak 's/^ENABLE_SELF_UPGRADE_MECHANISM = True$$/ENABLE_SELF_UPGRADE_MECHANISM = False/' googler
