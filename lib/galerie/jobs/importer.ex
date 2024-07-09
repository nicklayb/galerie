defmodule Galerie.Jobs.Importer do
  use Oban.Worker, queue: :imports

  alias Galerie.Folder
  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.Repo

  require Logger

  def enqueue(path, %Folder{id: folder_id, path: folder_path}) do
    if valid_picture?(path) do
      Logger.debug(
        "[#{inspect(__MODULE__)}] [enqueueing] Picture #{path} created, enqueueing import..."
      )

      %{path: path, folder_path: folder_path, folder_id: folder_id}
      |> Galerie.Jobs.Importer.new()
      |> Oban.insert()
    else
      Logger.warning("[#{inspect(__MODULE__)}] [invalid] File #{path} not an image")
      :noop
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"path" => path, "folder_path" => folder_path, "folder_id" => folder_id}
      }) do
    case Library.get_picture_by_path(path) do
      {:error, :not_found} ->
        %Picture{}
        |> Picture.create_changeset(%{
          fullpath: path,
          folder_path: folder_path,
          folder_id: folder_id
        })
        |> Repo.insert()
        |> Result.tap(&Galerie.PubSub.broadcast(Picture, {:imported, &1}))
        |> Result.log(
          &"[#{inspect(__MODULE__)}] [imported] [#{&1.id}] [#{&1.type}] #{path}",
          &"[#{inspect(__MODULE__)}] [not imported] #{inspect(&1)}"
        )
        |> Result.tap(fn %Picture{} = picture ->
          enqueue_post_steps(picture)
        end)

      {:ok, %Picture{} = picture} ->
        enqueue_post_steps(picture)
        :ok
    end
  end

  defp enqueue_post_steps(%Picture{} = picture) do
    picture
    |> tap(&enqueue_processor/1)
    |> tap(&enqueue_thumbnail_generator/1)
  end

  defp enqueue_processor(%Picture{} = picture), do: Galerie.Jobs.Processor.enqueue(picture)

  defp enqueue_thumbnail_generator(%Picture{} = picture),
    do: Galerie.Jobs.ThumbnailGenerator.enqueue(picture)

  def valid_picture?(path) do
    tiff_valid_picture?(path) or jpeg_valid_picture?(path)
  end

  defp jpeg_valid_picture?(path) do
    test_file_type?(path, &ExifParser.parse_jpeg_file/1)
  end

  defp tiff_valid_picture?(path) do
    test_file_type?(path, &ExifParser.parse_tiff_file/1)
  end

  defp test_file_type?(path, function) do
    path
    |> then(function)
    |> Result.succeeded?()
  rescue
    _ ->
      false
  end
end
