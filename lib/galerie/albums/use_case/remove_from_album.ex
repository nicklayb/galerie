defmodule Galerie.Albums.UseCase.RemoveFromAlbum do
  @moduledoc """
  Use case to remove a picture from an album.
  """
  use Galerie.UseCase

  require Ecto.Query
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Repo

  @impl Galerie.UseCase
  def validate(params, _options) do
    with {:ok, casted_params} <- validate_params(params),
         {:ok, :found} <- validate_existence(casted_params) do
      {:ok, casted_params}
    end
  end

  @impl Galerie.UseCase
  def run(multi, %{album_id: album_id, group_id: group_id} = params, _options) do
    multi
    |> Ecto.Multi.delete_all(:album_picture_group, relation_query(params))
    |> Ecto.Multi.put(:group_id, group_id)
    |> Ecto.Multi.put(:album_id, album_id)
  end

  @impl Galerie.UseCase
  def after_run(%{album_id: album_id, group_id: group_id}, _options) do
    Galerie.PubSub.broadcast({Album, album_id}, fn ->
      {:removed_from_album, %{album: load_album(album_id), group: Repo.get(Group, group_id)}}
    end)
  end

  defp load_album(album_id) do
    Album.Query.with_picture_count()
    |> Album.Query.by_ids(album_id)
    |> Repo.one()
  end

  defp relation_query(params) do
    album_id = Map.fetch!(params, :album_id)
    group_id = Map.fetch!(params, :group_id)

    Ecto.Query.where(
      AlbumPictureGroup,
      [album_picture_group],
      album_picture_group.album_id == ^album_id and
        album_picture_group.group_id == ^group_id
    )
  end

  defp validate_existence(params) do
    params
    |> relation_query()
    |> Repo.exists?()
    |> Result.from_boolean(:found, :not_found)
  end

  @types %{group_id: :binary_id, album_id: :binary_id}
  @schema {%{}, @types}
  @types_keys Map.keys(@types)
  defp validate_params(params) do
    @schema
    |> Ecto.Changeset.cast(params, @types_keys)
    |> Ecto.Changeset.validate_required(@types_keys)
    |> Ecto.Changeset.apply_action(:insert)
  end
end
