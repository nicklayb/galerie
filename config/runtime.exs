import Config

defmodule Env do
  def get(key, default \\ nil), do: System.get_env(key, default)

  def get!(key) do
    case System.get_env(key) do
      nil -> raise "Expected #{key} to be defined, got `#{nil}`"
      value -> value
    end
  end

  def uri(key, default \\ "") do
    key
    |> get(default)
    |> URI.parse()
  end

  def integer(key, default \\ nil) do
    key
    |> get("")
    |> Integer.parse()
    |> then(fn
      {integer, _} -> integer
      _ -> default
    end)
  end

  def boolean(key, default) do
    key
    |> get(default)
    |> then(&(&1 == "true"))
  end

  def atom(key, default) do
    key
    |> get(default)
    |> String.to_existing_atom()
  end

  def list!(key, splitter \\ "|") do
    key
    |> get!()
    |> String.split(splitter)
  end

  def list(key, default, splitter \\ "|") do
    key
    |> get(default)
    |> String.split(splitter)
    |> then(fn
      [] -> []
      [""] -> []
      other -> other
    end)
  end

  def atom(key, valid_atoms, default) do
    env_value = get(key, default)

    value =
      Enum.reduce_while(valid_atoms, nil, fn atom, _ ->
        if env_value == to_string(atom) do
          {:halt, atom}
        else
          {:cont, nil}
        end
      end)

    if is_nil(value) do
      raise "Expected #{key} to be a value in #{inspect(valid_atoms)}, got: #{env_value}"
    else
      value
    end
  end
end

release_stage = Env.get("RELEASE_STAGE", to_string(config_env()))

config :galerie, Oban,
  queues: [
    imports: Env.integer("GALERIE_QUEUE_IMPORTERS", 10),
    processors: Env.integer("GALERIE_QUEUE_PROCESSORS", 10),
    tiff_thumbnails: Env.integer("GALERIE_QUEUE_TIFF_THUMBNAILS", 3),
    thumbnails: Env.integer("GALERIE_QUEUE_THUMBNAILS", 10)
  ]

config :galerie, release_stage: release_stage

config :logger, level: Env.atom("LOGGER_LEVEL", "info")

config :galerie, Galerie.Repo,
  hostname: Env.get("DB_HOST", "localhost"),
  database: Env.get("DB_NAME", "galerie"),
  username: Env.get("DB_USER", "postgres"),
  password: Env.get("DB_PASS", "postgres")

config :galerie, Galerie.ObanRepo,
  hostname: Env.get("OBAN_DB_HOST", "localhost"),
  database: Env.get("OBAN_DB_NAME", "galerie_oban"),
  username: Env.get("OBAN_DB_USER", "postgres"),
  password: Env.get("OBAN_DB_PASS", "postgres")

if config_env() == :test do
  config :galerie, Galerie.Repo, database: "galerie_test"
  config :galerie, Galerie.ObanRepo, database: "galerie_oban_test"
end

config :galerie, Galerie.Accounts.User.Password,
  enforce_rules: Env.boolean("ENFORCE_PASSWORD_RULES", "true")

app_host = Env.uri("APP_HOST", "http://localhost:4000")
port = Env.integer("PORT", 4000)

config :galerie, GalerieWeb.Endpoint,
  http: [port: port],
  url: [host: app_host.host, scheme: app_host.scheme, port: app_host.port],
  secret_key_base: Env.get!("SECRET_KEY_BASE"),
  live_view: [signing_salt: Env.get!("LIVE_VIEW_SALT")]

mailer_from =
  case String.split(Env.get!("MAILER_FROM"), "|", parts: 2) do
    [email_address] -> email_address
    [email_address, name] -> {email_address, name}
  end

config :galerie, Galerie.Mailer, mailer_from: mailer_from

config :galerie, Galerie.FileControl.Supervisor,
  enabled: Env.boolean("GALERIE_FILE_CONTROL", "false"),
  folders: Env.list("GALERIE_FOLDERS", "")

config :galerie, Galerie.Directory,
  thumbnail: Env.get("GALERIE_THUMBNAILS"),
  raw_converted: Env.get("GALERIE_RAW_CONVERTED"),
  upload: Env.get("GALERIE_UPLOADS")

case {config_env(), Env.get("MAILER_ADAPTER", "local")} do
  {:test, _} ->
    config :galerie, Galerie.Mailer, adapter: Swoosh.Adapters.Test

  {_, "local"} ->
    config :galerie, Galerie.Mailer, adapter: Swoosh.Adapters.Local

  {_, "smtp"} ->
    config :galerie, Galerie.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: Env.get!("MAILER_SMTP_RELAY"),
      username: Env.get!("MAILER_SMTP_USERNAME"),
      password: Env.get!("MAILER_SMTP_PASSWORD"),
      ssl: Env.boolean("MAILER_SMTP_SSL", true),
      tls: Env.atom("MAILER_SMTP_TLS", ~w(always never if_available)a, "always"),
      auth: Env.atom("MAILER_SMTP_AUTH", ~w(always never if_available)a, "always")
end

config :sentry,
  dsn: Env.get("SENTRY_DSN"),
  environment_name: release_stage

if Env.boolean("ENABLE_SENTRY", "true") do
  config :sentry, included_environments: [release_stage]
else
  config :sentry, included_environments: []
end
