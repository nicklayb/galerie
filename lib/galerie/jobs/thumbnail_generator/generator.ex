defmodule Galerie.Jobs.ThumbnailGenerator.Generator do
  use Oban.Worker, queue: :thumbnails

  alias Galerie.Directory
  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.Repo

  def perform(%Oban.Job{args: %{"picture_id" => picture_id}}) do
    result =
      picture_id
      |> Library.get_picture()
      |> Result.and_then(&convert_raw/1)
      |> Result.and_then(&generate_thumbnail/1)
      |> Result.tap(fn picture ->
        Galerie.Jobs.Processor.enqueue(picture)
      end)

    case result do
      {:ok, picture} -> {:ok, picture}
      _ -> :discard
    end
  end

  defp convert_raw(%Picture{type: :tiff} = picture) do
    Galerie.Jobs.ThumbnailGenerator.ConvertRaw.convert(picture)
  end

  defp convert_raw(%Picture{} = picture), do: {:ok, picture}

  @thumbnail_size 400
  defp generate_thumbnail(%Picture{fullpath: fullpath} = picture) do
    thumbnail_path = Directory.thumbnail_output(fullpath)

    picture
    |> Picture.path(:jpeg)
    |> Result.succeed()
    |> Result.and_then(&Image.open/1)
    |> Result.and_then(&Image.thumbnail(&1, @thumbnail_size))
    |> Result.and_then(&Image.write(&1, thumbnail_path))
    |> Result.and_then(fn _ ->
      picture
      |> Picture.changeset(%{thumbnail: thumbnail_path})
      |> Repo.update()
      |> Result.tap(&Galerie.PubSub.broadcast(Picture, {:thumbnail_generated, &1}))
      |> Result.log(
        fn _ -> "[#{inspect(__MODULE__)}] [thumbnail] [#{picture.id}] [created]" end,
        &"[#{inspect(__MODULE__)}] [thumbnail] [#{picture.id}] [failed] #{inspect(&1)}"
      )
    end)
  end
end
