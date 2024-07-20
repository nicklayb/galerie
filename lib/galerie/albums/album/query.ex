defmodule Galerie.Albums.Album.Query do
  require Ecto.Query

  alias Galerie.Accounts.User
  alias Galerie.Albums.Album

  def from do
    Ecto.Query.from(Album, as: :album)
  end

  def by_ids(query \\ from(), album_ids) do
    Ecto.Query.where(query, [album: album], album.id in ^album_ids)
  end

  def with_picture_count(query \\ from()) do
    query
    |> Ecto.Query.join(:left, [album: album], groups in assoc(album, :groups), as: :groups)
    |> Ecto.Query.group_by([album: album], [album.id, album.name, album.user_id])
    |> Ecto.Query.select([album: album, groups: groups], %Album{
      id: album.id,
      name: album.name,
      user_id: album.user_id,
      picture_count: count(groups)
    })
  end

  def by_user(query \\ from(), user)
  def by_user(query, %User{id: user_id}), do: by_user(query, user_id)

  def by_user(query, user_id) do
    Ecto.Query.where(query, [album: album], album.user_id == ^user_id)
  end
end
