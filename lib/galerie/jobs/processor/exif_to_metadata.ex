defmodule Galerie.Jobs.Processor.ExifToMetadata do
  alias Galerie.Pictures.Picture

  @spec parse(Picture.t(), map()) :: map()
  def parse(%Picture{id: picture_id} = picture, picture_data) do
    exif = Map.get(picture_data, :exif, %{})
    gps = Map.Extra.get_with_default(picture_data, :gps, %{})

    {orientation, height, width} = get_orientation(picture, picture_data)

    %{
      orientation: orientation,
      rotation: get_rotation(picture_data),
      width: width,
      height: height,
      exposure_time: parse_exposure_time(Map.get(exif, :exposure_time)),
      f_number: Map.get(exif, :f_number),
      lens_model: Map.get(exif, :lens_model),
      camera_make: Map.get(picture_data, :make),
      camera_model: Map.get(picture_data, :model),
      datetime_original:
        format_date_time(Map.get(exif, :datetime_original), Map.get(exif, :time_offset)),
      longitude: get_gps(gps, :longitude),
      latitude: get_gps(gps, :latitude),
      picture_id: picture_id
    }
  end

  @negative_directions ~w(W S)
  defp get_gps(%{} = gps, side) do
    side_measure = Map.get(gps, String.to_existing_atom("gps_#{side}"))
    side_ref = Map.get(gps, String.to_existing_atom("gps_#{side}_ref"))

    case {side_measure, side_ref} do
      {[_, _, _] = side_measure, side} ->
        direction = if side in @negative_directions, do: -1, else: 1

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

  defp parse_exposure_time(number) when is_integer(number), do: Fraction.new(number)

  @fraction_regex ~r/([0-9]+)\/([0-9]+)/
  defp parse_exposure_time(string) when is_binary(string) do
    case Regex.scan(@fraction_regex, string) do
      [[_, numerator, demonimator]] ->
        Fraction.new(String.to_integer(numerator), String.to_integer(demonimator))

      _ ->
        string
        |> String.to_integer()
        |> Fraction.new()
    end
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

  defp get_rotation(%{orientation: orientation}) do
    cond do
      orientation =~ "90" -> 90
      orientation =~ "180" -> 180
      orientation =~ "270" -> 270
      true -> 0
    end
  end

  defp get_rotation(_), do: 0

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
end
