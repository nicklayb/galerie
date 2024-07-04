defmodule Nectarine.Application do
  use Application

  def start(_type, _args) do
    children = [
      Nectarine.Repo,
      Nectarine.ObanRepo,
      {Oban, Application.fetch_env!(:nectarine, Oban)},
      {Phoenix.PubSub, name: Nectarine.PubSub},
      {Task.Supervisor, name: Nectarine.MailerSupervisor},
      NectarineWeb.Telemetry,
      NectarineWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Nectarine.Supervisor)
  end

  def config_change(changed, _new, removed) do
    NectarineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
