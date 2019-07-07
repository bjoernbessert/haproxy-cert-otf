include env_make

# Set "export HAPROXY_MAIN_VERSION=X.X", otherwise make will use a default value
ifndef HAPROXY_MAIN_VERSION
override HAPROXY_MAIN_VERSION = 2.0
endif

build:
	docker build --build-arg HAPROXY_MAIN_VERSION="${HAPROXY_MAIN_VERSION}" -t $(NS)/$(REPO):$(VERSION) .

build-without-cache:
	docker build --build-arg HAPROXY_MAIN_VERSION="${HAPROXY_MAIN_VERSION}" -t $(NS)/$(REPO):$(VERSION) --rm=true --force-rm --no-cache .


.PHONY: build build-without-cache

