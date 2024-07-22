defmodule Galerie.Editor.Supervisor do
  use Supervisor

  alias Galerie.Accounts.User

  @name Galerie.Editor.Supervisor
  @registry_name Galerie.Editor.Registry
  @dynamic_supervisor_name Galerie.Editor.ManagerSupervisor
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: @name)
  end

  def init(_) do
    children = [
      {Registry, keys: :unique, name: @registry_name},
      {DynamicSupervisor, name: @dynamic_supervisor_name}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def open_editor(%User{id: user_id}, group_id) do
    DynamicSupervisor.start_child(
      @dynamic_supervisor_name,
      {Galerie.Editor.Manager, group_id: group_id, user_id: user_id, name: via_name(user_id)}
    )
  end

  def get_editor(%User{id: user_id}) do
    case Registry.lookup(@registry_name, user_id) do
      [{pid, _}] ->
        {:ok, pid}

      _ ->
        {:error, :no_editor_running}
    end
  end

  defp via_name(identifier) do
    {:via, Registry, {@registry_name, identifier}}
  end
end
