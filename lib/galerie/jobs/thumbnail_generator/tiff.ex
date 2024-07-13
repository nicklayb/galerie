defmodule Galerie.Jobs.ThumbnailGenerator.Tiff do
  use Oban.Worker, queue: :tiff_thumbnails

  alias Galerie.Picture

  @job __MODULE__

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> @job.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Galerie.Jobs.ThumbnailGenerator.Generator.perform(job)
  end
end
