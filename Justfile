docker_registry := "nboisvert"
docker_tag := "box"
docker_image := "galerie" + ":" + docker_tag
docker_remote_image := docker_registry / docker_image

default: dev

setup: boot-docker deps setup-assets create-db reset-db

dev: boot-docker create-db iex-server

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
	mv ./samples/DSC01569.JPG ./_temp_files/DSC01569.JPG
	mv ./samples/DSC01653.ARW ./_temp_files/DSC01653.ARW
	mv ./samples/DSC01804.ARW ./_temp_files/DSC01804.ARW
	rm -rf samples/*
	mv ./_temp_files/* ./samples/
	rm -rf _temp_files

boot-db:
	docker compose up -d db

boot-docker:
	docker compose up -d

iex:
	iex -S mix

iex-server:
	iex -S mix phx.server

docker-build:
	docker build -f ./dockerfiles/Dockerfile -t {{docker_image}} .

docker-tag:
	docker tag {{docker_image}} {{docker_remote_image}}

docker-push:
	docker push {{docker_remote_image}}

release-docker: docker-build docker-tag docker-push

destroy-docker:
	docker compose down --volumes

down:
	docker compose down

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

run-bash:
	docker run --rm -it --entrypoint bash --mount type=bind,source=./samples,destination=/samples -e MAILER_FROM=someone@gmail.com -e GALERIE_FOLDERS=/samples -e LIVE_VIEW_SALT=$(LIVE_VIEW_SALT)  -e SECRET_KEY_BASE=$(SECRET_KEY_BASE) $(DOCKER_IMAGE)

stop-processors:
	-sudo killall magick
	-sudo killall dcraw
	-sudo killall exiftool
