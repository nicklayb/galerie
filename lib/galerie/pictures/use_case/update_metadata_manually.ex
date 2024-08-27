defmodule Galerie.Pictures.UseCase.UpdateMetadataManually do
  use Galerie.UseCase

  require Ecto.Query

  alias Galerie.Pictures.Picture
  alias Galerie.Repo

  @impl Galerie.UseCase
  def validate(%{group_id: group_id, params: params}, _) do
    picture_metadatas =
      Picture.Metadata
      |> Ecto.Query.join(:left, [metadata], picture in assoc(metadata, :picture), as: :picture)
      |> Ecto.Query.where([picture: picture], picture.group_id == ^group_id)
      |> Repo.all()

    {:ok, %{group_id: group_id, picture_metadatas: picture_metadatas, params: params}}
  end

  @impl Galerie.UseCase
  def run(
        multi,
        %{group_id: group_id, picture_metadatas: picture_metadatas, params: params},
        _options
      ) do
    picture_metadatas
    |> Enum.reduce(multi, fn picture_metadata, multi ->
      changeset = Picture.Metadata.manual_edit_changeset(picture_metadata, params)
      updated_keys = Map.keys(changeset.changes)

      multi
      |> Ecto.Multi.update({:metadata, picture_metadata.id}, changeset)
      |> put_once(:updated_metadata, updated_keys)
    end)
    |> Ecto.Multi.run(:group, fn repo, _ ->
      repo.fetch(Picture.Group, group_id)
    end)
  end

  defp put_once(%Ecto.Multi{names: names} = multi, key, value) do
    if key in names do
      multi
    else
      Ecto.Multi.put(multi, key, value)
    end
  end

  @impl Galerie.UseCase
  def after_run(%{group: group, updated_metadata: updated_metadata}, _) do
    Galerie.PubSub.broadcast(
      {Picture.Group, group.id},
      {:metadata_updated, {updated_metadata, group}}
    )
  end

  @impl Galerie.UseCase
  def return(%{group: group}, _) do
    group
  end
end
