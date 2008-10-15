# cli-google Makefile

install:
	install -D -m755 google /usr/bin/google
	install -D -m644 google.1 /usr/share/man/man1/google.1
	install -D -m644 ChangeLog /usr/share/doc/cli-google/ChangeLog
	install -D -m644 README /usr/share/doc/cli-google/README
