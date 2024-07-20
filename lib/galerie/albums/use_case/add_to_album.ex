defmodule Galerie.Albums.UseCase.AddToAlbum do
  use Galerie.UseCase
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Repo

  @impl Galerie.UseCase
  def validate({%Album{} = album, [%Group{} | _] = groups}, _options) do
    group_ids = Enum.Extra.field(groups, :id)

    {:ok, {album, group_ids}}
  end

  def validate({%Album{} = album, [%Picture{} | _] = pictures}, _options) do
    group_ids = Enum.Extra.field(pictures, :group_id)
    {:ok, {album, group_ids}}
  end

  def validate({%Album{} = album, group_ids}, _options) do
    {:ok, {album, List.wrap(group_ids)}}
  end

  @impl Galerie.UseCase
  def run(multi, {%Album{id: album_id} = album, group_ids}, _options) do
    %Album{groups: groups} = Repo.preload(album, :groups)

    group_ids
    |> Enum.reject(fn id -> Enum.any?(groups, &(&1.id == id)) end)
    |> Enum.uniq()
    |> Enum.reduce(multi, fn group_id, multi ->
      Ecto.Multi.insert(
        multi,
        {:album_picture_group, group_id},
        AlbumPictureGroup.changeset(%{group_id: group_id, album_id: album_id})
      )
    end)
    |> Ecto.Multi.update(:touch_album, Repo.touch_changeset(album))
  end

  @impl Galerie.UseCase
  def return(_, options) do
    {%Album{id: album_id}, _} = Keyword.fetch!(options, :params)

    album_id
    |> Album.Query.by_ids()
    |> Repo.one()
    |> Repo.preload([:groups])
  end
end
