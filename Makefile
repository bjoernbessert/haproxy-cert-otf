.PHONY: clean test

test:
	bats tests/
clean:
	docker-compose kill
	docker-compose rm -f

