defmodule Galerie.Jobs.Processor do
  use Oban.Worker, queue: :processors

  alias Galerie.Jobs.Processor.ExifToMetadata
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Exif
  alias Galerie.Pictures.Picture.Metadata
  alias Galerie.Repo

  def enqueue(%Picture{id: picture_id}) do
    enqueue(picture_id)
  end

  def enqueue(picture_id) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.Processor.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"picture_id" => picture_id}}) do
    case Pictures.get_picture(picture_id) do
      {:ok, %Picture{} = picture} ->
        picture
        |> Repo.preload([:exif, :metadata])
        |> process()

      _ ->
        :discard
    end
  end

  defp process(
         %Picture{
           id: picture_id,
           exif: picture_exif,
           metadata: picture_metadata
         } = picture
       ) do
    exif =
      picture
      |> extract_exif()
      |> Result.map(&normalize/1)
      |> Result.with_default(%{})

    upsert_exif(picture_exif, picture_id, exif)
    upsert_metadata(picture_metadata, picture, exif)

    :ok
  end

  defp upsert_metadata(nil, picture, exif),
    do: upsert_metadata(%Metadata{}, picture, exif)

  defp upsert_metadata(
         %Metadata{} = picture_metadata,
         %Picture{id: picture_id} = picture,
         exif_data
       ) do
    params = ExifToMetadata.parse(picture, exif_data)

    picture_metadata
    |> Metadata.changeset(params)
    |> Repo.insert_or_update()
    |> Result.log(
      &"[#{inspect(__MODULE__)}] [metadata] [#{&1.picture_id}] [processed]",
      &"[#{inspect(__MODULE__)}] [metadata] [#{picture_id}] [failed] #{inspect(&1)}"
    )
  end

  defp upsert_exif(nil, picture_id, exif), do: upsert_exif(%Exif{}, picture_id, exif)

  defp upsert_exif(%Exif{} = picture_exif, picture_id, exif) do
    picture_exif
    |> Exif.changeset(%{picture_id: picture_id, exif: exif})
    |> Repo.insert_or_update()
    |> Result.tap(&Galerie.PubSub.broadcast(Picture, {:processed, &1}))
    |> Result.log(
      &"[#{inspect(__MODULE__)}] [exif] [#{&1.picture_id}] [processed]",
      &"[#{inspect(__MODULE__)}] [exif] [#{picture_id}] [failed] #{inspect(&1)}"
    )
  end

  defp extract_exif(%Picture{fullpath: fullpath, type: :jpeg}) do
    extract_exif(fullpath)
  end

  defp extract_exif(%Picture{converted_jpeg: converted_jpeg, type: :tiff}) do
    extract_exif(converted_jpeg)
  end

  defp extract_exif(path) do
    path
    |> Image.open!()
    |> Image.exif()
  end

  defp normalize(exif), do: exif

  defimpl Jason.Encoder, for: [Image.Exif.Gps] do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Jason.Encode.map(opts)
    end
  end
end
