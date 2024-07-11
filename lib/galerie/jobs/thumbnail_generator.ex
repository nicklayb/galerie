defmodule Galerie.Jobs.ThumbnailGenerator do
  use Oban.Worker, queue: :thumbnails

  alias Galerie.Picture

  def enqueue(%Picture{id: picture_id}) do
    %{picture_id: picture_id}
    |> Galerie.Jobs.ThumbnailGenerator.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Galerie.Jobs.ThumbnailGenerator.Generator.perform(job)
  end
end
