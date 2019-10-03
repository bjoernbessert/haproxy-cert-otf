.PHONY: clean test

test:
	bats tests/
clean:
	docker-compose kill
	docker-compose rm -f

preapre-local-dev-environment:
	cd /tmp && git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local
	cd dockerfiles/apache && make
	cd dockerfiles/haproxy && make