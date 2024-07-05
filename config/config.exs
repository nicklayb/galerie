import Config

config :galerie,
  ecto_repos: [Galerie.Repo, Galerie.ObanRepo],
  environment: config_env()

config :galerie, Oban,
  repo: Galerie.ObanRepo,
  queues: [imports: 10, processors: 10]

config :galerie, Galerie.ObanRepo, priv: "priv/oban"

config :galerie, Galerie.Generator, default_max_tries: 3

config :galerie, Galerie.Repo, migration_primary_key: [name: :id, type: :binary_id]

config :galerie, GalerieWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "czNpciKyTe+8fnrhDOJB4j1v2EyoExjgKsDy1KWYWXyHadR0ZbwtmnLDoWGKaE+h",
  render_errors: [view: GalerieWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Galerie.PubSub,
  live_view: [signing_salt: "SwHEX71s"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  backends: [:console, Sentry.LoggerBackend]

config :phoenix, :json_library, Jason

config :sentry,
  enable_source_code_context: true,
  included_environments: [:prod],
  root_source_code_paths: [File.cwd!()]

config :esbuild,
  version: "0.14.0",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.5",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/css/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"
