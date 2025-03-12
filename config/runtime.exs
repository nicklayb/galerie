import Config

release_stage = Box.Config.get("RELEASE_STAGE", default: to_string(config_env()))

config :galerie, Oban,
  queues: [
    imports: Box.Config.int("GALERIE_QUEUE_IMPORTERS", default: "10"),
    processors: Box.Config.int("GALERIE_QUEUE_PROCESSORS", default: "10"),
    tiff_thumbnails: Box.Config.int("GALERIE_QUEUE_TIFF_THUMBNAILS", default: "3"),
    thumbnails: Box.Config.int("GALERIE_QUEUE_THUMBNAILS", default: "10"),
    pictures_aggregation: Box.Config.int("GALERIE_PICTURE_AGGREGATION", default: "10")
  ]

config :galerie, release_stage: release_stage

config :logger, level: Box.Config.atom("LOGGER_LEVEL", default: "info")

db_hostname = Box.Config.get("DB_HOST", default: "localhost")
db_name = Box.Config.get("DB_NAME", default: "galerie", test: "galerie_test")
db_user = Box.Config.get("DB_USER", default: "postgres")
db_pass = Box.Config.get("DB_PASS", default: "postgres")

config :galerie, Galerie.Repo,
  hostname: db_hostname,
  database: db_name,
  username: db_user,
  password: db_pass

config :galerie, Galerie.ObanRepo,
  hostname: Box.Config.get("OBAN_DB_HOST", default: db_hostname),
  database: Box.Config.get("OBAN_DB_NAME", default: "#{db_name}_oban", test: "galerie_oban_test"),
  username: Box.Config.get("OBAN_DB_USER", default: db_user),
  password: Box.Config.get("OBAN_DB_PASS", default: db_pass)

config :galerie, Galerie.Accounts.User.Password,
  enforce_rules: Box.Config.bool("ENFORCE_PASSWORD_RULES", default: "true")

app_host = Box.Config.uri("APP_HOST", default: "http://localhost:4000")
port = Box.Config.int("PORT", default: "4000")

config :galerie, GalerieWeb.Endpoint,
  http: [port: port],
  url: [host: app_host.host, scheme: app_host.scheme, port: app_host.port],
  secret_key_base: Box.Config.get!("SECRET_KEY_BASE"),
  live_view: [signing_salt: Box.Config.get!("LIVE_VIEW_SALT")]

mailer_from =
  case String.split(Box.Config.get!("MAILER_FROM"), "|", parts: 2) do
    [email_address] -> email_address
    [email_address, name] -> {email_address, name}
  end

config :galerie, Galerie.Mailer, mailer_from: mailer_from

config :galerie, Galerie.FileControl.Supervisor,
  enabled: Box.Config.bool("GALERIE_FILE_CONTROL", default: "false"),
  folders: Box.Config.list("GALERIE_FOLDERS", default: ""),
  hidden_files: Box.Config.bool("GALERIE_HIDDEN_FILES", default: "false")

config :galerie, Galerie.Directory,
  thumbnail: Box.Config.get("GALERIE_THUMBNAILS", default: ""),
  raw_converted: Box.Config.get("GALERIE_RAW_CONVERTED", default: ""),
  upload: Box.Config.get("GALERIE_UPLOADS", default: "")

case {config_env(), Box.Config.get("MAILER_ADAPTER", default: "local")} do
  {:test, _} ->
    config :galerie, Galerie.Mailer, adapter: Swoosh.Adapters.Test

  {_, "local"} ->
    config :galerie, Galerie.Mailer, adapter: Swoosh.Adapters.Local

  {_, "smtp"} ->
    config :galerie, Galerie.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: Box.Config.get!("MAILER_SMTP_RELAY"),
      username: Box.Config.get!("MAILER_SMTP_USERNAME"),
      password: Box.Config.get!("MAILER_SMTP_PASSWORD"),
      ssl: Box.Config.bool("MAILER_SMTP_SSL", default: "true"),
      tls:
        Box.Config.atom("MAILER_SMTP_TLS",
          values: ~w(always never if_available)a,
          default: "always"
        ),
      auth:
        Box.Config.atom("MAILER_SMTP_AUTH",
          values: ~w(always never if_available)a,
          default: "always"
        )
end

config :sentry,
  dsn: Box.Config.get("SENTRY_DSN", default: ""),
  environment_name: release_stage

if Box.Config.bool("ENABLE_SENTRY", default: "true") do
  config :sentry, included_environments: [release_stage]
else
  config :sentry, included_environments: []
end
