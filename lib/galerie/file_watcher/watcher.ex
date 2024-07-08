defmodule Galerie.FileControl.Watcher do
  use GenServer

  alias Galerie.Library
  require Logger

  def start_link(args) do
    folder = Keyword.fetch!(args, :folder)

    if not File.dir?(folder) do
      raise """
      Invalid folder: #{folder}
      """
    end

    GenServer.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  def init(args) do
    folder = Keyword.fetch!(args, :folder)

    send(self(), :synchronize)

    {:ok, %{folder: folder}}
  end

  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{inspect(events)}] #{path}")

    if Enum.member?(events, :closed) or Enum.member?(events, :moved_to) do
      enqueue_importer(path)
    end

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    {:noreply, state}
  end

  def handle_info(:start_file_system, %{folder: folder} = state) do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [folder])
    FileSystem.subscribe(watcher_pid)

    Logger.info("[#{inspect(__MODULE__)}] [watcher] [#{folder}] [started]")
    {:noreply, Map.put(state, :watcher_pid, watcher_pid)}
  end

  def handle_info(:synchronize, %{folder: folder} = state) do
    Logger.info("[#{inspect(__MODULE__)}] [synchronize] [#{folder}] [started]")
    synchronize(folder)
    send(self(), :start_file_system)
    Logger.info("[#{inspect(__MODULE__)}] [synchronize] [#{folder}] [completed]")
    {:noreply, state}
  end

  defp enqueue_importer(path) do
    Galerie.Jobs.Importer.enqueue(path)
  end

  defp synchronize(folder) do
    files = list_files(folder)

    existing = Library.list_imported_paths(files)

    Enum.map(files -- existing, &enqueue_importer/1)
  end

  defp list_files(folder) do
    Galerie.Folder.ls_recursive(folder, [], fn
      {:ok, file}, acc ->
        [file | acc]

      error, acc ->
        Logger.error(
          "[#{inspect(__MODULE__)}] [synchronize] [#{folder}] [error] #{inspect(error)}"
        )

        acc
    end)
  end
end
