defmodule Galerie.Application do
  use Application

  def start(_type, _args) do
    children =
      [
        Galerie.Repo,
        Galerie.ObanRepo,
        {Phoenix.PubSub, name: Galerie.PubSub},
        {Oban, Application.fetch_env!(:galerie, Oban)},
        {Task.Supervisor, name: Galerie.MailerSupervisor},
        GalerieWeb.Telemetry,
        GalerieWeb.Endpoint,
        Galerie.FileControl.Supervisor
      ]

    Galerie.ObanRepo.Reporter.attach()

    Supervisor.start_link(children, strategy: :one_for_one, name: Galerie.Supervisor)
  end

  def config_change(changed, _new, removed) do
    GalerieWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
