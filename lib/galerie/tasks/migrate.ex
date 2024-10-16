defmodule Galerie.Tasks.Migrate do
  @moduledoc "Migrates database"
  import Ecto.Query

  require Logger
  alias Galerie.Accounts.User
  alias Galerie.Repo

  @app :galerie
  @main_repo Galerie.Repo
  def run do
    load_app()

    for repo <- repos() do
      create_repo(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    {:ok, _, _} =
      Ecto.Migrator.with_repo(@main_repo, fn _repo ->
        maybe_create_first_user()
      end)
  end

  defp create_repo(repo) do
    case repo.__adapter__().storage_up(repo.config()) do
      :ok ->
        log_info("#{inspect(repo)} Database created")

      {:error, :already_up} ->
        log_info("#{inspect(repo)} Database already existing")

      {:error, error} ->
        log_error("#{inspect(repo)} Database creation error #{inspect(error)}")
        raise error
    end
  end

  def rollback(repo) do
    rollback(repo, last_migration(repo))
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp last_migration(repo) do
    "schema_migrations"
    |> select([:version])
    |> repo.all()
    |> List.last()
    |> Map.get(:version)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp log_info(message), do: Logger.info("[#{inspect(__MODULE__)}] #{message}")
  defp log_error(message), do: Logger.error("[#{inspect(__MODULE__)}] #{message}")

  @password "Admin123"
  defp maybe_create_first_user do
    if not Repo.exists?(User) do
      {:ok, %User{} = user} =
        Galerie.Accounts.create_user(
          %{
            email: "admin@example.com",
            password: @password,
            password_confirmation: @password,
            first_name: "Admin",
            last_name: "Admin",
            is_admin: true
          },
          after_run?: false
        )

      log_info("""
      Initial admin user created, use the following credentials to login:

      Email: #{user.email}
      Password: #{@password}

      ** Don't forget to change these if the platform is meant to be publicly exposed
      """)
    end
  end
end
