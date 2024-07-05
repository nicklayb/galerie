defmodule Galerie.Jobs.ThumbnailGenerator do
  use Oban.Worker, queue: :thumbnails

  alias Galerie.Picture

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.ThumbnailGenerator.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"picture_id" => picture_id}}) do
    case Library.get_picture(picture_id) do
      {:ok, %Picture{} = picture} ->
        picture
        |> convert_raw()
        |> generate_thumbnail()

      _ ->
        :discard
    end
  end

  defp convert_raw(%Picture{type: :tiff} = picture) do
    Galerie.Jobs.ThumbnailGenerator.ConvertRaw.convert(picture)
  end

  defp convert_raw(%Picture{} = picture), do: picture

  defp generate_thumbnail(%Picture{} = picture) do
  end
end
