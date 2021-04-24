PHP_VER ?= 8.0
TAG ?= dev

.PHONY: build
build:
	docker build -t "nanointeractive/swoole-dev:$(PHP_VER)-$(TAG)" --compress .

.PHONY: run
run:
	docker run --rm -it nanointeractive/swoole-dev:$(PHP_VER)-$(TAG) bash

.PHONY: remove
remove:
	docker image rm --force nanointeractive/swoole-dev:$(PHP_VER)-$(TAG)

.PHONY: clean
clean:
	docker container prune
	docker image prune

