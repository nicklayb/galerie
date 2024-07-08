defmodule Galerie.Jobs.Processor do
  use Oban.Worker, queue: :processors

  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.PictureExif
  alias Galerie.PictureMetadata
  alias Galerie.Repo

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.Processor.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"picture_id" => picture_id}}) do
    case Library.get_picture(picture_id) do
      {:ok, %Picture{} = picture} ->
        picture
        |> Repo.preload([:picture_exif, :picture_metadata])
        |> process()

      _ ->
        :discard
    end
  end

  defp process(
         %Picture{
           id: picture_id,
           picture_exif: picture_exif,
           picture_metadata: picture_metadata
         } = picture
       ) do
    exif =
      picture
      |> extract_exif()
      |> Result.map(&normalize/1)
      |> Result.with_default(%{})

    upsert_exif(picture_exif, picture_id, exif)
    upsert_metadata(picture_metadata, picture_id, exif)

    :ok
  end

  defp upsert_metadata(nil, picture_id, exif),
    do: upsert_metadata(%PictureMetadata{}, picture_id, exif)

  defp upsert_metadata(%PictureMetadata{} = picture_metadata, picture_id, exif_data) do
    exif = Map.get(exif_data, :exif, %{})
    gps = Map.Extra.get_with_default(exif_data, :gps, %{})

    {orientation, height, width} = get_orientation(exif_data)

    params = %{
      orientation: orientation,
      width: width,
      height: height,
      exposure_time: Map.get(exif, :exposure_time),
      f_number: Map.get(exif, :f_number),
      lens_model: Map.get(exif, :lens_model),
      make: Map.get(exif_data, :make),
      model: Map.get(exif_data, :model),
      datetime_original:
        format_date_time(Map.get(exif, :date_time_original), Map.get(exif, :unknown)),
      longitude: Map.get(gps, :longitude),
      latitude: Map.get(gps, :latitude),
      picture_id: picture_id
    }

    picture_metadata
    |> PictureMetadata.changeset(params)
    |> Repo.insert_or_update()
    |> Result.log(
      &"[#{inspect(__MODULE__)}] [metadata] [#{&1.picture_id}] [processed]",
      &"[#{inspect(__MODULE__)}] [metadata] [#{picture_id}] [failed] #{inspect(&1)}"
    )
  end

  defp upsert_exif(nil, picture_id, exif), do: upsert_exif(%PictureExif{}, picture_id, exif)

  defp upsert_exif(%PictureExif{} = picture_exif, picture_id, exif) do
    picture_exif
    |> PictureExif.changeset(%{picture_id: picture_id, exif: exif})
    |> Repo.insert_or_update()
    |> Result.tap(&Galerie.PubSub.broadcast(Picture, {:processed, &1}))
    |> Result.log(
      &"[#{inspect(__MODULE__)}] [exif] [#{&1.picture_id}] [processed]",
      &"[#{inspect(__MODULE__)}] [exif] [#{picture_id}] [failed] #{inspect(&1)}"
    )
  end

  def format_date_time(nil, _timezone), do: nil

  @datetime_regex ~r/([0-9]{4})[-:]([0-9]{2})[-:]([0-9]{2}) ?([0-9]{2}):([0-9]{2}):([0-9]{2})/
  def format_date_time(string, timezone) do
    case Regex.scan(@datetime_regex, string) do
      [[_, year, month, day, hour, minute, second]] ->
        [year, month, day, hour, minute, second]
        |> Enum.map(&String.to_integer/1)
        |> then(&apply(NaiveDateTime, :new, &1))
        |> Result.with_default(nil)
        |> shift_timezone(timezone)

      _ ->
        nil
    end
  end

  defp extract_exif(%Picture{fullpath: fullpath, type: :jpeg}) do
    ExifParser.parse_jpeg_file(fullpath)
  end

  defp extract_exif(%Picture{fullpath: fullpath, type: :tiff}) do
    ExifParser.parse_tiff_file(fullpath)
  end

  defp normalize(%{ifd0: ifd0}), do: ifd0

  defp shift_timezone(nil, _), do: nil

  @timezone_regex ~r/([-+])([0-9]{2}):?([0-9]{2})/
  defp shift_timezone(%NaiveDateTime{} = naive_datetime, timezone) do
    case Regex.scan(@timezone_regex, timezone) do
      [[_, sign, hours, minutes]] ->
        sign = if sign == "-", do: 1, else: -1

        Enum.reduce([hour: hours, minute: minutes], naive_datetime, fn {unit, part}, acc ->
          NaiveDateTime.add(acc, String.to_integer(part) * sign, unit)
        end)

      _ ->
        naive_datetime
    end
  end

  defp get_orientation(%{
         orientation: 1,
         exif: %{pixel_y_dimension: height, pixel_x_dimension: width}
       }),
       do: {:landscape, height, width}

  defp get_orientation(%{exif: %{pixel_y_dimension: width, pixel_x_dimension: height}}),
    do: {:portrait, height, width}
end
