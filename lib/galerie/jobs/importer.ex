defmodule Galerie.Jobs.Importer do
  use Oban.Worker, queue: :imports

  alias Galerie.Library
  alias Galerie.Picture
  alias Galerie.Repo

  def enqueue(path) do
    %{path: path}
    |> Galerie.Jobs.Importer.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"path" => path}}) do
    case Library.get_picture_by_path(path) do
      {:error, :not_found} ->
        %Picture{}
        |> Picture.create_changeset(%{fullpath: path})
        |> Repo.insert()
        |> Result.tap(fn %Picture{} = picture ->
          enqueue_post_steps(picture)
        end)

      {:ok, %Picture{} = picture} ->
        enqueue_post_steps(picture)
        :ok
    end
  end

  defp enqueue_post_steps(%Picture{} = picture) do
    picture
    |> enqueue_processor()
    |> enqueue_thumbnail_generator()
  end

  defp enqueue_processor(%Picture{} = picture), do: Galerie.Jobs.Processor.enqueue(picture)

  defp enqueue_thumbnail_generator(%Picture{} = picture),
    do: Galerie.Jobs.ThumbnailGenerator.enqueue(picture)
end
