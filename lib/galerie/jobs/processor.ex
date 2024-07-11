defmodule Galerie.Jobs.Processor do
  use Oban.Worker, queue: :processors

  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.PictureExif
  alias Galerie.PictureMetadata
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
    upsert_metadata(picture_metadata, picture, exif)

    :ok
  end

  defp upsert_metadata(nil, picture, exif),
    do: upsert_metadata(%PictureMetadata{}, picture, exif)

  defp upsert_metadata(
         %PictureMetadata{} = picture_metadata,
         %Picture{id: picture_id} = picture,
         exif_data
       ) do
    exif = Map.get(exif_data, :exif, %{})
    gps = Map.Extra.get_with_default(exif_data, :gps, %{})

    {orientation, height, width} = get_orientation(picture, exif_data)

    params = %{
      orientation: orientation,
      width: width,
      height: height,
      exposure_time: parse_exposure_time(Map.get(exif, :exposure_time)),
      f_number: Map.get(exif, :f_number),
      lens_model: Map.get(exif, :lens_model),
      camera_make: Map.get(exif_data, :make),
      camera_model: Map.get(exif_data, :model),
      datetime_original:
        format_date_time(Map.get(exif, :datetime_original), Map.get(exif, :time_offset)),
      longitude: get_gps(gps, :longitude),
      latitude: get_gps(gps, :latitude),
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

  defp get_gps(%{} = gps, side) do
    side_measure = Map.get(gps, String.to_existing_atom("gps_#{side}"))
    side_ref = Map.get(gps, String.to_existing_atom("gps_#{side}_ref"))

    case {side_measure, side_ref} do
      {[_, _, _] = side_measure, side} ->
        direction = if side in ["W", "S"], do: -1, else: 1

        to_decimal(side_measure) * direction

      _ ->
        nil
    end
  end

  defp to_decimal([degree, minutes, seconds]) do
    degree + minutes / 60 + seconds / 3600
  end

  defp to_decimal(_), do: nil

  defp parse_exposure_time(nil), do: nil

  @fraction_regex ~r/([0-9+])\/([0-9+])/
  defp parse_exposure_time(string) when is_binary(string) do
    case Regex.scan(@fraction_regex, string) do
      [[_, numerator, demonimator]] ->
        String.to_integer(numerator) / String.to_integer(demonimator)

      _ ->
        String.to_integer(string)
    end
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

  defp format_date_time(nil, _timezone), do: nil

  @datetime_regex ~r/([0-9]{4})[-:]([0-9]{2})[-:]([0-9]{2}) ?([0-9]{2}):([0-9]{2}):([0-9]{2})/
  defp format_date_time(string, timezone) when is_binary(string) do
    case Regex.scan(@datetime_regex, string) do
      [[_, year, month, day, hour, minute, second]] ->
        [year, month, day, hour, minute, second]
        |> Enum.map(&String.to_integer/1)
        |> then(&apply(NaiveDateTime, :new, &1))
        |> Result.with_default(nil)
        |> format_date_time(timezone)

      _ ->
        nil
    end
  end

  defp format_date_time(%NaiveDateTime{} = date_time, timezone) do
    shift_timezone(date_time, timezone)
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

  defp get_orientation(%Picture{}, %{
         orientation: orientation,
         exif: %{
           exif_image_height: height,
           exif_image_width: width
         }
       }) do
    cond do
      width == height ->
        {:square, height, width}

      orientation =~ "90" or orientation =~ "270" ->
        {:portrait, width, height}

      true ->
        {:landscape, height, width}
    end
  end

  defp get_orientation(%Picture{} = picture, _) do
    image =
      picture
      |> Picture.path(:jpeg)
      |> Image.open!()

    width = Image.width(image)
    height = Image.height(image)

    orientation =
      cond do
        width > height ->
          :landscape

        height > width ->
          :portrait

        true ->
          :square
      end

    {orientation, height, width}
  end

  defimpl Jason.Encoder, for: [Image.Exif.Gps] do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Jason.Encode.map(opts)
    end
  end
end
