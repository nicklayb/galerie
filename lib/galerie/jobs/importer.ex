defmodule Galerie.Jobs.Importer do
  use Oban.Worker, queue: :imports

  alias Galerie.Folders.Folder
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture

  require Logger

  def enqueue(path, %Folder{id: folder_id, path: folder_path}) do
    if Pictures.valid_file_type?(path) do
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
    case Pictures.get_picture_by_path(path) do
      {:error, :not_found} ->
        %{
          fullpath: path,
          folder_path: folder_path,
          folder_id: folder_id
        }
        |> Pictures.insert_picture()
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
    enqueue_thumbnail_generator(picture)
  end

  defp enqueue_thumbnail_generator(%Picture{} = picture),
    do: Galerie.Jobs.Thumbnail.enqueue(picture)
end
