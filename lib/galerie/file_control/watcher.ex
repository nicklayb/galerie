defmodule Galerie.FileControl.Watcher do
  use GenServer

  alias Galerie.Folders.Folder
  alias Galerie.Pictures
  require Logger

  def start_link(args) do
    folder =
      args
      |> Keyword.fetch!(:folder)
      |> Path.expand()

    if not File.dir?(folder) do
      raise """
      Invalid folder: #{folder}
      """
    end

    GenServer.start_link(__MODULE__, [folder: folder], name: Keyword.fetch!(args, :name))
  end

  def init(args) do
    folder_path = Keyword.fetch!(args, :folder)
    folder = Galerie.Folders.get_or_create_folder!(folder_path)

    send(self(), :synchronize)

    {:ok, %{folder_path: folder_path, folder: folder}}
  end

  def handle_info(
        {:file_event, watcher_pid, {path, events}},
        %{folder: folder, watcher_pid: watcher_pid} = state
      ) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{inspect(events)}] #{path}")

    if new_file_event?(events) do
      enqueue_importer(path, folder)
    end

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    {:noreply, state}
  end

  def handle_info(:start_file_system, %{folder: %Folder{path: path}} = state) do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [path])
    FileSystem.subscribe(watcher_pid)

    Logger.info("[#{inspect(__MODULE__)}] [watcher] [#{path}] [started]")
    {:noreply, Map.put(state, :watcher_pid, watcher_pid)}
  end

  def handle_info(:synchronize, %{folder: %Folder{path: path} = folder} = state) do
    Logger.info("[#{inspect(__MODULE__)}] [synchronize] [#{path}] [started]")
    synchronize(folder)
    send(self(), :start_file_system)
    Logger.info("[#{inspect(__MODULE__)}] [synchronize] [#{path}] [completed]")
    {:noreply, state}
  end

  def terminate(reason, %{folder: %Folder{path: path}}) do
    Logger.info("[#{inspect(__MODULE__)}] [#{path}] [stopped] #{reason}")
    :ok
  end

  defp new_file_event?(events) do
    cond do
      :is_dir in events ->
        false

      :closed in events ->
        true

      :moved_to in events ->
        true

      true ->
        false
      end
    end

  defp enqueue_importer(path, %Folder{} = folder) do
    Galerie.Jobs.Importer.enqueue(path, folder)
  end

  defp synchronize(%Folder{path: path} = folder) do
    files = list_files(path)

    existing = Pictures.list_imported_paths(files)

    Enum.map(files -- existing, &enqueue_importer(&1, folder))
  end

  defp list_files(folder_path) do
    Galerie.Directory.ls_recursive(folder_path, [], fn
      {:ok, file}, acc ->
        [file | acc]

      error, acc ->
        Logger.error(
          "[#{inspect(__MODULE__)}] [synchronize] [#{folder_path}] [error] #{inspect(error)}"
        )

        acc
    end)
  end
end
