defmodule Galerie.Pictures.UseCase.SetMainPicture do
  use Galerie.UseCase

  require Ecto.Query

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Repo

  @impl Galerie.UseCase
  def validate(picture_id, _options) do
    case get_group(picture_id) do
      {_group_id, ^picture_id} ->
        {:error, :already_main_picture}

      {group_id, _} ->
        {:ok, {group_id, picture_id}}

      _ ->
        {:error, :picture_not_found}
    end
  end

  defp get_group(picture_id) do
    Group
    |> Ecto.Query.join(:left, [group], pictures in assoc(group, :pictures), as: :pictures)
    |> Ecto.Query.where([pictures: pictures], pictures.id == ^picture_id)
    |> Ecto.Query.select([group], {group.id, group.main_picture_id})
    |> Repo.one()
  end

  @impl Galerie.UseCase
  def run(multi, {group_id, picture_id}, _options) do
    multi
    |> Ecto.Multi.one(:group, Ecto.Query.where(Group, [group], group.id == ^group_id))
    |> Ecto.Multi.update(:updated_group, fn %{group: group} ->
      Group.changeset(group, %{main_picture_id: picture_id})
    end)
  end

  @impl Galerie.UseCase
  def after_run(%{updated_group: %Group{folder_id: folder_id} = group}, _) do
    Galerie.PubSub.broadcast({Folder, folder_id}, {:main_picture_updated, group})
  end

  @impl Galerie.UseCase
  def return(%{updated_group: group}, _) do
    group
  end
end
