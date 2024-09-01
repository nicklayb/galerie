defmodule Galerie.FileControl.Supervisor do
  @moduledoc """
  The file control supervisor is responsible for starting file
  watcher for every watched folders. They individual folder's
  watcher path are kept in a registry.

  The state of the supervisor is under the `:enabled` key in config
  and watched folders are pulled from the config and are expected
  to be defined as a list of string under the `:folders` key like

      config :galerie, Galerie.FileControl.Supervisor,
        enabled: false,
        folders: [
            "folder1",
            "folder2"
          ]
  """
  use Supervisor, restart: :transient

  @supervisor Galerie.FileControl.Supervisor
  @registry Galerie.FileControl.Registry
  def start_link(args) do
    if enabled?() do
      Supervisor.start_link(__MODULE__, args, name: @supervisor)
    else
      :ignore
    end
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
    Galerie.Env.config!(@supervisor, :folders)
  end

  defp enabled? do
    not Galerie.Env.test?() and Galerie.Env.config(@supervisor, :enabled)
  end
end
