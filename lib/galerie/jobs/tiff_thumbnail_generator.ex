defmodule Galerie.Jobs.TiffThumbnailGenerator do
  use Oban.Worker, queue: :tiff_thumbnails

  alias Galerie.Picture

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.TiffThumbnailGenerator.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Galerie.Jobs.ThumbnailGenerator.Generator.perform(job)
  end
end
