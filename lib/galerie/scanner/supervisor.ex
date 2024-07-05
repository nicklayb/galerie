defmodule Galerie.Scanner.Supervisor do
  use Supervisor

  @supervisor __MODULE__
  @registry Galerie.Scanner.Registry
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: @supervisor)
  end

  def init(_) do
    children = [
      {Registry, keys: :unique, name: @registry}
    ]

    folder_scanner =
      :galerie
      |> Application.get_env(@supervisor)
      |> Keyword.fetch!(:folders)
      |> String.split("|")
      |> Enum.map(fn folder ->
        {Galerie.Scanner, folder: folder, name: {:via, Registry, {@registry, folder}}}
      end)

    Supervisor.init(children ++ folder_scanner, strategy: :one_for_one)
  end
end
