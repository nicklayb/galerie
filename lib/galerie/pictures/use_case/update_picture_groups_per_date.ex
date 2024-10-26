defmodule Galerie.Pictures.UseCase.UpdatePictureGroupsPerDate do
  use Galerie.UseCase

  require Ecto.Query

  alias Galerie.Pictures.PictureGroupsPerDate

  @impl Galerie.UseCase
  def run(multi, %{folder_id: folder_id, date: date, count: count}, _options) do
    multi
    |> Ecto.Multi.run(:picture_groups_per_date, fn repo, _ ->
      PictureGroupsPerDate
      |> Ecto.Query.where(
        [picture_groups_per_date],
        picture_groups_per_date.date == ^date and picture_groups_per_date.folder_id == ^folder_id
      )
      |> repo.one()
      |> Result.succeed()
    end)
    |> Ecto.Multi.put(:count, count)
    |> Ecto.Multi.run(:updated_picture_groups_per_date, fn
      _repo, %{picture_groups_per_date: nil, count: 0} ->
        {:ok, nil}

      repo,
      %{
        picture_groups_per_date: %PictureGroupsPerDate{} = picture_groups_per_date,
        count: 0
      } ->
        repo.delete(picture_groups_per_date)

      repo,
      %{
        picture_groups_per_date: nil,
        count: count
      } ->
        %{count: count, folder_id: folder_id, date: date}
        |> PictureGroupsPerDate.changeset()
        |> repo.insert()

      repo,
      %{
        picture_groups_per_date: %PictureGroupsPerDate{} = picture_groups_per_date,
        count: count
      } ->
        picture_groups_per_date
        |> PictureGroupsPerDate.changeset(%{count: count})
        |> repo.update()
    end)
  end

  @impl Galerie.UseCase
  def return(%{updated_picture_groups_per_date: picture_groups_per_date}, _) do
    picture_groups_per_date
  end
end
