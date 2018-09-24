include env_make

.PHONY: build build-without-cache

build:
	docker build -t $(NS)/$(REPO):$(VERSION) .

build-without-cache:
	docker build -t $(NS)/$(REPO):$(VERSION) --rm=true --force-rm --no-cache .

