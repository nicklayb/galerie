import Config

config :galerie, GalerieWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: false,
  server: true

config :logger, level: :info
