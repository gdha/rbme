DPKG=dpkg
DPKG_OPTS=-b
name = rbme
specfile = $(name).spec

.PHONY: info repo deb

TOPLEVEL = rbme rbme.conf DEBIAN

GITREV := HEAD

VERSION := $(shell git rev-list $(GITREV) -- $(TOPLEVEL) 2>/dev/null| wc -l)$(EXTRAREV)
distversion = 1.$(VERSION)

info: deb
	dpkg-deb -I out/*_all.deb
	dpkg-deb -c out/*_all.deb

deb:	clean
	rm -Rf build
	mkdir -p out build/DEBIAN
	setfacl -b out build
	chmod -vR g-s+rx,o+rx build
	install -m 0644 rbme.conf -D build/etc/rbme.conf
	install -m 0755 rbme -D build/usr/bin/rbme
	sed -i -e 's/VERSION=.*/VERSION=$(distversion)/' build/usr/bin/rbme
	install -m 0644 -t build/DEBIAN DEBIAN/*
	sed -i -e 's/Version:.*/Version: $(distversion)/' build/DEBIAN/control
	mkdir -p build/usr/share/doc/rbme
	mv build/DEBIAN/copyright build/usr/share/doc/rbme/copyright
	git log | gzip -n9 >build/usr/share/doc/rbme/changelog.gz
	chmod -R g-w build
	fakeroot ${DPKG} ${DPKG_OPTS} build out
	rm -Rf build
	lintian --suppress-tags binary-without-manpage -i out/*_all.deb
	git add -A


clean:
	rm -fr out build

dist: clean dist/$(name)-$(distversion).tar.gz

dist/$(name)-$(distversion).tar.gz:
	@echo -e "\033[1m== Building archive $(name)-$(distversion) ==\033[0;0m"
	mkdir -p -m 0755 dist;
	sed -i -e 's/Version: .*/Version: $(distversion)/' rbme.spec;
	tar -czf dist/$(name)-$(distversion).tar.gz --transform='s,^,$(name)-$(distversion)/,S' \
	Makefile rbme* LICENSE README NEWS

rpm: dist
	@echo -e "\033[1m== Building RPM package $(name)-$(distversion)==\033[0;0m"
	rpmbuild -ta --clean \
		--define "_rpmfilename dist/%%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
		--define "debug_package %{nil}" \
		--define "_rpmdir %(pwd)" dist/$(name)-$(distversion).tar.gz
