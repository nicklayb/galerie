.PHONY: dev boot-db iex create-db docker-build docker-tag docker-push release-docker iex-server down clean deps setup

DOCKER_REGISTRY=hal:5000
DOCKER_TAG:=latest
DOCKER_IMAGE=galerie:$(DOCKER_TAG)
DOCKER_REMOTE_IMAGE=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)

setup: asdf-install boot-docker deps setup-assets create-db reset-db

dev: boot-docker create-db iex-server

asdf-install:
	asdf install

setup-assets:
	npm install --prefix assets

create-db:
	mix ecto.create

reset: reset-samples remove-files reset-db

reset-db: remove-files
	mix ecto.reset

reset-samples:
	mkdir -p _temp_files
	mv ./samples/DSC00397.JPG ./_temp_files/DSC00397.JPG
	mv ./samples/DSC00413.JPG ./_temp_files/DSC00413.JPG
	mv ./samples/DSC00461.jpg ./_temp_files/DSC00461.jpg
	mv ./samples/DSC01569.ARW ./_temp_files/DSC01569.ARW
	mv ./samples/DSC01653.ARW ./_temp_files/DSC01653.ARW
	mv ./samples/DSC01804.ARW ./_temp_files/DSC01804.ARW
	rm -rf samples/*
	mv ./_temp_files/* ./samples/
	rm -rf _temp_files

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

remove-files: remove-thumbnail-files remove-converted-files remove-uploaded-files

remove-thumbnail-files:
	rm -rf ./priv/thumbnails/*

remove-converted-files:
	rm -rf ./priv/raw_converted/*

remove-uploaded-files:
	rm -rf ./priv/uploads/*
