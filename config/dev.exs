import Config

config :galerie, Galerie.Repo,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :galerie, Galerie.ObanRepo,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :galerie, Oban,
  repo: Galerie.ObanRepo,
  plugins: [{Oban.Plugins.Lifeline, rescue_after: :timer.minutes(1)}]

config :galerie, GalerieWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    npx: [
      "cpx",
      "./static/**/*",
      "../priv/static",
      "-v",
      "--watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/galerie_web/(live|views)/.*(ex)$",
      ~r"lib/galerie_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :logger, backends: [:console, GalerieWeb.Logger.Backend]

config :logger, GalerieWeb.Logger.Backend,
  pub_sub_server: Galerie.PubSub,
  config_file: "../.logger.astral.json"

config :phoenix, :plug_init_mode, :runtime

config :phoenix, :stacktrace_depth, 20
