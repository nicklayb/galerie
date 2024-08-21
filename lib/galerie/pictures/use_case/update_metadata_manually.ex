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
      Ecto.Multi.update(
        multi,
        {:metadata, picture_metadata.id},
        Picture.Metadata.manual_edit_changeset(picture_metadata, params)
      )
    end)
    |> Ecto.Multi.run(:group, fn repo, _ ->
      repo.fetch(Picture.Group, group_id)
    end)
  end

  @impl Galerie.UseCase
  def after_run(%{group: _group}, _) do
  end

  @impl Galerie.UseCase
  def return(%{group: group}, _) do
    group
  end
end
