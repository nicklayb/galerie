defmodule Galerie.Albums do
  require Ecto.Query
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPicture
  alias Galerie.Pictures.Picture
  alias Galerie.Repo

  @type picture_or_id :: Picture.t() | String.t()
  @type picture_or_pictures :: picture_or_id() | [picture_or_id()]

  @spec create_album(User.t(), map()) :: Result.t(Album.t(), any())
  def create_album(%User{id: user_id}, params) do
    %Album{}
    |> Album.changeset(Map.Extra.put(params, :user_id, user_id))
    |> Repo.insert()
  end

  @spec add_to_album(Album.t(), picture_or_pictures()) :: Result.t(Album.t(), any())
  def add_to_album(%Album{} = album, [%Picture{} | _] = pictures) do
    picture_ids = Enum.Extra.field(pictures, :id)

    add_to_album(album, picture_ids)
  end

  def add_to_album(%Album{id: album_id} = album, picture_ids) when is_list(picture_ids) do
    %Album{pictures: pictures} = Repo.preload(album, :pictures)

    picture_ids
    |> Enum.reject(fn id -> Enum.any?(pictures, &(&1.id == id)) end)
    |> Enum.reduce(Ecto.Multi.new(), fn picture_id, multi ->
      Ecto.Multi.insert(
        multi,
        {:album_picture, picture_id},
        AlbumPicture.changeset(%{picture_id: picture_id, album_id: album_id})
      )
    end)
    |> Repo.transaction()
    |> Result.map(fn _ ->
      Repo.reload_assoc(album, [:pictures])
    end)
  end

  def add_to_album(%Album{} = album, picture_or_picture_id) do
    add_to_album(album, List.wrap(picture_or_picture_id))
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
