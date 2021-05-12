PHP_VER ?= 7.4

.PHONY: build
build:
	docker build -t nanointeractive/phalcon4-dev:$(PHP_VER) --compress .

.PHONY: run
run:
	docker run --rm -it nanointeractive/phalcon4-dev:$(PHP_VER) bash

.PHONY: remove
remove:
	docker image rm --force nanointeractive/phalcon4-dev:$(PHP_VER)

.PHONY: clean
clean:
	docker container prune
	docker image prune

