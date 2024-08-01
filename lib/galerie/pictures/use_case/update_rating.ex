defmodule Galerie.Pictures.UseCase.UpdateRating do
  use Galerie.UseCase

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture.Group

  @impl Galerie.UseCase
  def run(multi, %{group_id: group_id, rating: rating}, _options) do
    multi
    |> Ecto.Multi.run(:group, fn repo, _ ->
      repo.fetch(Group, group_id)
    end)
    |> Ecto.Multi.update(:updated_group, fn %{group: group} ->
      rating = if group.rating == rating, do: nil, else: rating
      Group.changeset(group, %{rating: rating})
    end)
  end

  @impl Galerie.UseCase
  def after_run(%{updated_group: %Group{folder_id: folder_id} = group}, _) do
    Galerie.PubSub.broadcast({Folder, folder_id}, {:rating_updated, group})
  end

  @impl Galerie.UseCase
  def return(%{updated_group: group}, _) do
    group
  end
end
