#!/bin/sh
set -e

BINARY_PATH=/opt/rel/galerie/bin/galerie

sleep 5

$BINARY_PATH eval "Galerie.Tasks.Migrate.run()"

exec $BINARY_PATH "$@"
