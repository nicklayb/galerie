defmodule Galerie.Jobs.Importer do
  use Oban.Worker, queue: :imports

  alias Galerie.Folders.Folder
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureGroup
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
    case Pictures.get_picture_by_path(path) do
      {:error, :not_found} ->
        %{
          fullpath: path,
          folder_path: folder_path,
          folder_id: folder_id
        }
        |> insert_picture()
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

  defp insert_picture(params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:picture, Picture.create_changeset(params))
    |> Ecto.Multi.run(:picture_group, fn repo,
                                         %{
                                           picture: %Picture{
                                             name: name,
                                             group_name: group_name,
                                             folder_id: folder_id
                                           }
                                         } ->
      case repo.get_by(PictureGroup, group_name: group_name) do
        %PictureGroup{} = group ->
          {:ok, group}

        nil ->
          %{group_name: group_name, name: name, folder_id: folder_id}
          |> PictureGroup.changeset()
          |> repo.insert()
      end
    end)
    |> Ecto.Multi.update(:picture_with_group, fn %{
                                                   picture_group: %PictureGroup{id: group_id},
                                                   picture: %Picture{} = picture
                                                 } ->
      Picture.changeset(picture, %{picture_group_id: group_id})
    end)
    |> Ecto.Multi.run(:group_with_main_picture, fn repo,
                                                   %{
                                                     picture_group:
                                                       %PictureGroup{
                                                         main_picture_id: main_picture_id
                                                       } = picture_group,
                                                     picture: %Picture{id: picture_id}
                                                   } ->
      if is_nil(main_picture_id) do
        picture_group
        |> PictureGroup.changeset(%{main_picture_id: picture_id})
        |> repo.update()
      else
        {:ok, picture_group}
      end
    end)
    |> Repo.transaction()
    |> Repo.unwrap_transaction(:picture_with_group)
  end

  defp enqueue_post_steps(%Picture{} = picture) do
    enqueue_thumbnail_generator(picture)
  end

  defp enqueue_thumbnail_generator(%Picture{} = picture),
    do: Galerie.Jobs.Thumbnail.enqueue(picture)

  def valid_picture?(path) do
    tiff_valid_picture?(path) or basic_valid_picture?(path)
  end

  defp basic_valid_picture?(path) do
    test_file_type?(path, &Image.open/1)
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
