.PHONY: dev boot-db iex create-db docker-build docker-tag docker-push release-docker iex-server down clean deps setup

DOCKER_REGISTRY=hal:5000
DOCKER_TAG:=latest
DOCKER_IMAGE=nectarine:$(DOCKER_TAG)
DOCKER_REMOTE_IMAGE=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)

setup: asdf-install boot-docker deps setup-assets create-db reset-db iex-server

dev: boot-docker create-db iex-server

asdf-install:
	asdf install

setup-assets:
	npm install --prefix assets

create-db:
	mix ecto.create

reset-db:
	mix ecto.reset

boot-db:
	docker-compose up -d db

boot-docker:
	docker-compose up -d

iex:
	iex -S mix

iex-server:
	iex -S mix phx.server

docker-build:
	docker build -f ./dockerfiles/Dockerfile -t $(DOCKER_IMAGE) .

docker-tag:
	docker tag $(DOCKER_IMAGE) $(DOCKER_REMOTE_IMAGE)

docker-push:
	docker push $(DOCKER_REMOTE_IMAGE)

release-docker: docker-build docker-tag docker-push

destroy-docker:
	docker-compose down --volumes

down:
	docker-compose down

clean:
	rm -rf _build deps

refresh: clean deps

fresh-start: destroy-docker clean setup

deps:
	mix deps.get

