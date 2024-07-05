defmodule Galerie.Jobs.ThumbnailGenerator do
  use Oban.Worker, queue: :thumbnails

  alias Galerie.Folder
  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.Repo

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.ThumbnailGenerator.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"picture_id" => picture_id}}) do
    picture_id
    |> Library.get_picture()
    |> Result.and_then(&convert_raw/1)
    |> Result.and_then(&generate_thumbnail/1)
    |> Result.with_default(:discard)
  end

  defp convert_raw(%Picture{type: :tiff} = picture) do
    Galerie.Jobs.ThumbnailGenerator.ConvertRaw.convert(picture)
  end

  defp convert_raw(%Picture{} = picture), do: {:ok, picture}

  @thumbnail_size 400
  defp generate_thumbnail(%Picture{fullpath: fullpath} = picture) do
    thumbnail_path = Folder.thumbnail_output(fullpath)

    picture
    |> Picture.jpeg_path()
    |> Result.and_then(&Image.open/1)
    |> Result.and_then(&Image.thumbnail(&1, @thumbnail_size))
    |> Result.and_then(&Image.write(&1, thumbnail_path))
    |> Result.and_then(fn _ ->
      picture
      |> Picture.changeset(%{thumbnail_path: thumbnail_path})
      |> Repo.update()
    end)
  end
end
