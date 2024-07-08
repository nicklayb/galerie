# Galerie

Web photos library

## Requirements

- [`asdf`](https://asdf-vm.com/) (with `elixir`, `erlang` and `nodejs` plugins)
- [`make`](https://www.gnu.org/software/make/manual/make.html)
- [`direnv`](https://direnv.net/)
- [`exiftool`](https://exiftool.org/)
- [`dcraw`](https://github.com/ncruces/dcraw)
- [`imagemagick`](https://imagemagick.org/index.php)

## File type support

- TIFF-compatible files (so far, only tested with Sony's ARW).
- JPEG

## How processing works

Once the `Galerie.FileControl.Watcher` finds a new file:

1. A job is enqueued for importing the file through `Galerie.Jobs.Importer`. This only imports the file in the database.
2. Two jobs are then enqueued:
  1. `Galerie.Jobs.Processor`: for ExIF extracting and basic metadata extraction.
  2. `Galerie.Jobs.ThumbnailGenerator`: Responsible for generating a JPEG (if the file is a TIFF), then generating a thumbnail from this JPEG (uses the original JPEG if possible)
3. Then the file should be considered "Processed" and should be visible from the app  

## Contributing

1. Clone the repository: `git clone git@github.com:nicklayb/galerie.git`
2. Load env variables: `direnv allow`
3. Setup the app: `make setup` (will install `asdf`, `nodejs` and `elixir` dependencies; create the db and seed it)
4. Start the app: `make dev`

When starting, the `Galerie.FileControl.Watcher` will start synchronizing the folder `./samples` and importing/processing pictures. This folder's content is gitignored except for the file already present so you can reuse it to put your own pictures for testing.

Once the initial syncrhonization is completed, the `Watcher` enters a watch mode where it'll wait for new file. Dropping file while the app runs should enqueue jobs for them directly.

The default seeded user's credentials should be `admin@example.com` with `admin` as password.
