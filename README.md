# Galerie

Web photos library with processing various operations.

## Requirements

- [`asdf`](https://asdf-vm.com/) (with `elixir`, `erlang` and `nodejs` plugins)
- [`make`](https://www.gnu.org/software/make/manual/make.html)
- [`direnv`](https://direnv.net/)
- [`exiftool`](https://exiftool.org/)
- [`dcraw`](https://github.com/ncruces/dcraw)
- [`imagemagick`](https://imagemagick.org/index.php)


## Information

### File type support

- TIFF-compatible files (so far, only tested with Sony's ARW).
- JPEG

### How processing works

Once the `Galerie.FileControl.Watcher` finds a new file:

1. A job is enqueued for importing the file through `Galerie.Jobs.Importer`. This only imports the file in the database.
2. Two jobs are then enqueued:
  1. `Galerie.Jobs.Processor`: for ExIF extracting and basic metadata extraction.
  2. `Galerie.Jobs.ThumbnailGenerator`: Responsible for generating a JPEG (if the file is a TIFF), then generating a thumbnail from this JPEG (uses the original JPEG if possible)
3. Then the file should be considered "Processed" and should be visible from the app

### SSL support

There is no builtin SSL support so far and I am not planning on adding any since I'm using it behind a [Traefik](https://traefik.io/traefik/) reverse proxy. Though any contribution is welcome to implement it.

## Contributing

1. Clone the repository: `git clone git@github.com:nicklayb/galerie.git`
2. Load env variables: `direnv allow`
3. Setup the app: `make setup` (will install `asdf`, `nodejs` and `elixir` dependencies; create the db and seed it)
4. Start the app: `make dev`

When starting, the `Galerie.FileControl.Watcher` will start synchronizing the folder `./samples` and importing/processing pictures. This folder's content is gitignored except for the file already present so you can reuse it to put your own pictures for testing.

Once the initial syncrhonization is completed, the `Watcher` enters a watch mode where it'll wait for new file. Dropping file while the app runs should enqueue jobs for them directly.

The default seeded user's credentials should be `admin@example.com` with `admin` as password.

### Customizing env variables

To override the env variables, you can create a `.galerie_envrc` up your file tree and any overrides to the following

- `GALERIE_FOLDERS`: List of folders to watch seperated by pipe (`|`); defaults to `./samples`
- `GALERIE_QUEUE_IMPORTERS`: Number of concurrent importers, defaults to `10`
- `GALERIE_QUEUE_PROCESSORS`: Number of concurrent processors, defaults to `10`
- `GALERIE_QUEUE_THUMBNAILS`: Number of concurrent thumbnail generators, defaults to `3`. Note, these workers are CPU intensive for TIFF files as they run te `priv/scripts/autorun` script.

- `DB_HOST`: Host of the DB, defaults to `localhost`
- `DB_NAME`: Name of the DB, defaults to `galerie`
- `DB_USER`: Username of the DB, defaults to `postgres` 
- `DB_PASS`: Password of the DB, defaults to `postgres`

_For Oban, you can use the same host, username and password as the standard database like it's configured by default if wanna have them together_

- `OBAN_DB_HOST`: Oban database host, defaults to `localhost`
- `OBAN_DB_NAME`: Oban database name, defaults to `galerie_oban`
- `OBAN_DB_USER`: Oban database username, defaults to `postgres`
- `OBAN_DB_PASS`: Oban database password, defaults to `postgres`
