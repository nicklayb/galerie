defmodule Galerie.Scanner do
  use GenServer

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
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [folder])
    FileSystem.subscribe(watcher_pid)

    Logger.info("[#{inspect(__MODULE__)}] Start scanning #{folder}")

    {:ok,
     %{
       folder: folder,
       watcher_pid: watcher_pid
     }}
  end

  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    if Enum.member?(events, :created) and picture?(path) do
      Logger.debug("Picture #{path} created, enqueueing import...")
      Galerie.Jobs.Importer.enqueue(path)
    end

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    {:noreply, state}
  end

  defp picture?(path) do
    tiff_picture?(path) or jpeg_picture?(path)
  end

  defp jpeg_picture?(path) do
    path
    |> ExifParser.parse_jpeg_file()
    |> Result.succeeded?()
  end

  defp tiff_picture?(path) do
    path
    |> ExifParser.parse_tiff_file()
    |> Result.succeeded?()
  end
end
