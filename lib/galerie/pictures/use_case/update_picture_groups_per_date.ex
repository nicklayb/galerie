defmodule Galerie.Pictures.UseCase.UpdatePictureGroupsPerDate do
  use Galerie.UseCase

  require Ecto.Query

  alias Galerie.Pictures.Picture.Group
  alias Galerie.Pictures.PictureGroupsPerDate

  @impl Galerie.UseCase
  def run(multi, %{folder_id: folder_id, date: date}, _options) do
    multi
    |> Ecto.Multi.run(:count_picture_groups, fn repo, _ ->
      Ecto.Query.from(group in Group, as: :group)
      |> Ecto.Query.join(:inner, [group: group], main_picture in assoc(group, :main_picture),
        as: :main_picture
      )
      |> Ecto.Query.join(
        :inner,
        [main_picture: main_picture],
        metadata in assoc(main_picture, :metadata),
        as: :metadata
      )
      |> Ecto.Query.where(
        [group: group, metadata: metadata],
        group.folder_id == ^folder_id and type(metadata.datetime_original, :date) == ^date
      )
      |> repo.aggregate(:count)
    end)
    |> Ecto.Multi.run(:picture_groups_per_date, fn repo, _ ->
      PictureGroupsPerDate
      |> Ecto.Query.where(
        [picture_groups_per_date],
        picture_groups_per_date.date == ^date and picture_groups_per_date.folder_id == ^folder_id
      )
      |> repo.one()
    end)
    |> Ecto.Multi.run(:updated_picture_groups_per_date, fn
      _repo, %{picture_groups_per_date: nil, count_picture_groups: 0} ->
        {:ok, nil}

      repo,
      %{
        picture_groups_per_date: %PictureGroupsPerDate{} = picture_groups_per_date,
        count_picture_groups: 0
      } ->
        repo.delete(picture_groups_per_date)

      repo,
      %{
        picture_groups_per_date: nil,
        count_picture_groups: count
      } ->
        %{count: count, folder_id: folder_id, date: date}
        |> PictureGroupsPerDate.changeset()
        |> repo.insert()

      repo,
      %{
        picture_groups_per_date: %PictureGroupsPerDate{} = picture_groups_per_date,
        count_picture_groups: count
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
