import Config

config :nectarine,
  ecto_repos: [Nectarine.Repo, Nectarine.ObanRepo],
  environment: config_env()

config :nectarine, Oban, repo: Nectarine.ObanRepo, queues: [default: 10]

config :nectarine, Nectarine.ObanRepo, priv: "priv/oban"

config :nectarine, Nectarine.Generator, default_max_tries: 3

config :nectarine, Nectarine.Repo, migration_primary_key: [name: :id, type: :binary_id]

config :nectarine, NectarineWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "czNpciKyTe+8fnrhDOJB4j1v2EyoExjgKsDy1KWYWXyHadR0ZbwtmnLDoWGKaE+h",
  render_errors: [view: NectarineWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nectarine.PubSub,
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
