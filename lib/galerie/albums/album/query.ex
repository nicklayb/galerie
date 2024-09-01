defmodule Galerie.Albums.Album.Query do
  @moduledoc """
  Module responsible for query building the album schema.
  """
  require Ecto.Query

  alias Galerie.Accounts.User
  alias Galerie.Albums.Album

  @doc """
  Base query with named binding.
  """
  @spec from() :: Ecto.Query.t()
  def from do
    Ecto.Query.from(Album, as: :album)
  end

  @doc """
  Queries the schema by or or more primary key.
  """
  @spec by_ids(Ecto.Queryable.t(), [Ecto.UUID.t()] | Ecto.UUID.t()) :: Ecto.Query.t()
  def by_ids(query \\ from(), album_ids) do
    Ecto.Query.where(query, [album: album], album.id in ^List.wrap(album_ids))
  end

  @doc """
  Joins and groups the album to select the picture count per albums.
  """
  @spec with_picture_count(Ecto.Queryable.t()) :: Ecto.Query.t()
  def with_picture_count(query \\ from()) do
    query
    |> Ecto.Query.join(:left, [album: album], groups in assoc(album, :groups), as: :groups)
    |> Ecto.Query.group_by([album: album], [album.id, album.name, album.user_id])
    |> Ecto.Query.select([album: album, groups: groups], %Album{
      album
      | picture_count: count(groups)
    })
  end

  @doc """
  Queries for albums belonging to a given user
  """
  @spec by_user(Ecto.Queryable.t(), User.t() | Ecto.UUID.t()) :: Ecto.Query.t()
  def by_user(query \\ from(), user)
  def by_user(query, %User{id: user_id}), do: by_user(query, user_id)

  def by_user(query, user_id) do
    Ecto.Query.where(query, [album: album], album.user_id == ^user_id)
  end
end
