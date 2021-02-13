PHP_VER ?= 7.4
TAG ?= dev

.PHONY: build
build:
	docker build -t "brossquad/php-dev:$(PHP_VER)-$(TAG)" --compress .

.PHONY: run
run:
	docker run --rm -it brossquad/php-dev:$(PHP_VER)-$(TAG) bash

.PHONY: remove
remove:
	docker image rm --force brossquad/php-dev:$(PHP_VER)-$(TAG)

.PHONY: clean
clean:
	docker container prune
	docker image prune

