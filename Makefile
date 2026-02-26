.PHONY: build test release install clean app

VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
NEXT_VERSION ?= $(VERSION)

build:
	swift build -c release

test:
	swift test

app: test
	./scripts/package_app.sh $(NEXT_VERSION)

install: app
	cp -R ClipShield.app /Applications/
	@echo "Installed ClipShield.app to /Applications"

clean:
	rm -rf .build *.dmg ClipShield.app
