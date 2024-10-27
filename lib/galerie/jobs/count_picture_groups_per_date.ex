defmodule Galerie.Jobs.CountPictureGroupsPerDate do
  alias Galerie.Folders.Folder
  alias Galerie.Pictures.PictureGroupsPerDate
  use Oban.Worker, queue: :pictures_aggregation

  require Ecto.Query
  require Logger

  alias Galerie.Pictures
  alias Galerie.Repo

  @debounce_key Galerie.Jobs.CountPictureGroupsPerDate
  @debounce_delay :timer.seconds(3)
  def debounce(folder_id, date) do
    Galerie.TaskDebouncer.debounce(
      {@debounce_key, folder_id, date},
      {Galerie.Jobs.CountPictureGroupsPerDate, :enqueue, [folder_id, date]},
      timeout: @debounce_delay
    )
  end

  def enqueue_all do
    Folder
    |> Ecto.Query.select([folder], folder.id)
    |> Repo.all()
    |> Enum.each(&enqueue/1)
  end

  def enqueue(folder_id, date \\ nil) do
    %{folder_id: folder_id, date: date}
    |> Galerie.Jobs.CountPictureGroupsPerDate.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"folder_id" => folder_id, "date" => date_raw}}) do
    {:ok, date} = Ecto.Type.cast(:date, date_raw)

    folder_id
    |> Pictures.count_per_date(date)
    |> with_existing_records(date, folder_id)
    |> Enum.reduce([], fn {current_date, count}, acc ->
      result =
        Galerie.UseCase.execute(
          Galerie.Pictures.UseCase.UpdatePictureGroupsPerDate,
          %{
            date: current_date,
            count: count,
            folder_id: folder_id
          },
          []
        )

      case result do
        {:ok, _} ->
          acc

        error ->
          [{folder_id, current_date, error} | acc]
      end
    end)
    |> log_errors()
  end

  def with_existing_records(records, date, folder_id) do
    folder_id
    |> Pictures.picture_groups_per_date(date)
    |> Enum.reduce(records, fn {date, _count}, acc ->
      Map.put_new(acc, date, 0)
    end)
  end

  defp log_errors(errors) do
    Enum.each(errors, fn {folder_id, date, error} ->
      Logger.error("[#{inspect(__MODULE__)}] [#{folder_id}] [#{date}] #{inspect(error)}")
    end)
  end
end
