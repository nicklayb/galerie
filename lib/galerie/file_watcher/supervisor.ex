defmodule Galerie.FileControl.Supervisor do
  use Supervisor

  @supervisor __MODULE__
  @registry Galerie.FileControl.Registry
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: @supervisor)
  end

  def init(_) do
    children = [
      {Registry, keys: :unique, name: @registry}
    ]

    folders = folders()

    watchers = watchers(folders)

    Supervisor.init(children ++ watchers, strategy: :one_for_one)
  end

  defp watchers(folders) do
    Enum.map(folders, fn folder ->
      {Galerie.FileControl.Watcher, folder: folder, name: {:via, Registry, {@registry, folder}}}
    end)
  end

  defp folders do
    :galerie
    |> Application.get_env(@supervisor)
    |> Keyword.fetch!(:folders)
    |> String.split("|")
  end
end
