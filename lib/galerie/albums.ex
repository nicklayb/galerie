defmodule Galerie.Albums do
  require Ecto.Query
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Repo

  @type picture_or_id :: Picture.t() | String.t()
  @type picture_or_pictures :: picture_or_id() | [picture_or_id()]

  def get_user_albums(%User{id: user_id}), do: get_user_albums(user_id)

  def get_user_albums(user_id) do
    Album
    |> Ecto.Query.where([album], album.user_id == ^user_id)
    |> Ecto.Query.join(:left, [album], groups in assoc(album, :groups), as: :groups)
    |> Ecto.Query.group_by([album], [album.id, album.name, album.user_id])
    |> Ecto.Query.select([album, groups: groups], %Album{
      id: album.id,
      name: album.name,
      user_id: album.user_id,
      picture_count: count(groups)
    })
    |> Repo.all()
  end

  @spec create_album(User.t(), map()) :: Result.t(Album.t(), any())
  def create_album(%User{id: user_id}, params) do
    %Album{}
    |> Album.changeset(Map.Extra.put(params, :user_id, user_id))
    |> Repo.insert()
  end

  def attach_picture_groups_to_albums(album_ids, group_ids) do
    Album
    |> Ecto.Query.select([album], %Album{id: album.id})
    |> Ecto.Query.where([album], album.id in ^album_ids)
    |> Repo.all()
    |> Enum.map(fn %Album{} = album ->
      add_to_album(album, group_ids)
    end)
  end

  @spec add_to_album(Album.t(), picture_or_pictures()) :: Result.t(Album.t(), any())
  def add_to_album(%Album{} = album, [%Picture{} | _] = pictures) do
    group_ids = Enum.Extra.field(pictures, :group_id)

    add_to_album(album, group_ids)
  end

  def add_to_album(%Album{} = album, [%Group{} | _] = groups) do
    group_ids = Enum.Extra.field(groups, :id)

    add_to_album(album, group_ids)
  end

  def add_to_album(%Album{id: album_id} = album, group_ids) when is_list(group_ids) do
    %Album{groups: groups} = Repo.preload(album, :groups)

    group_ids
    |> Enum.reject(fn id -> Enum.any?(groups, &(&1.id == id)) end)
    |> Enum.uniq()
    |> Enum.reduce(Ecto.Multi.new(), fn group_id, multi ->
      Ecto.Multi.insert(
        multi,
        {:album_group_group, group_id},
        AlbumPictureGroup.changeset(%{group_id: group_id, album_id: album_id})
      )
    end)
    |> Repo.transaction()
    |> Result.map(fn _ ->
      Repo.reload_assoc(album, [:groups])
    end)
  end

  def add_to_album(%Album{} = album, pictures_or_group_ids) do
    add_to_album(album, List.wrap(pictures_or_group_ids))
  end

  @spec remove_from_album(Album.t(), picture_or_pictures()) :: Result.t(Album.t(), any())
  def remove_from_album(%Album{} = album, [%Picture{} | _] = pictures) do
    picture_ids = Enum.Extra.field(pictures, :id)

    remove_from_album(album, picture_ids)
  end

  def remove_from_album(%Album{} = album, picture_ids) when is_list(picture_ids) do
    album
    |> Ecto.assoc(:albums_pictures)
    |> Ecto.Query.where([album_picture], album_picture.picture_id in ^picture_ids)
    |> Repo.delete_all()
    |> then(fn _ ->
      Repo.reload_assoc(album, [:pictures])
    end)
    |> Result.succeed()
  end

  def remove_from_album(%Album{} = album, picture_or_picture_id) do
    remove_from_album(album, List.wrap(picture_or_picture_id))
  end
end
