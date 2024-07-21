defmodule Galerie.Albums do
  require Ecto.Query
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.UseCase
  alias Galerie.Pictures.Picture
  alias Galerie.Repo

  @type picture_or_id :: Picture.t() | String.t()
  @type picture_or_pictures :: picture_or_id() | [picture_or_id()]

  def get_user_albums(%User{id: user_id}), do: get_user_albums(user_id)

  def get_user_albums(user_id) do
    user_id
    |> Album.Query.by_user()
    |> Album.Query.with_picture_count()
    |> Ecto.Query.order_by([album: album], {:desc, album.updated_at})
    |> Repo.all()
  end

  @spec create_album(User.t(), map(), Keyword.t()) :: Result.t(Album.t(), any())
  def create_album(user, params, options \\ []) do
    UseCase.CreateAlbum.execute({user, params}, options)
  end

  def attach_picture_groups_to_albums(album_ids, group_ids, options \\ []) do
    album_ids
    |> Album.Query.by_ids()
    |> Repo.all()
    |> Enum.map(fn %Album{} = album ->
      UseCase.AddToAlbum.execute({album, group_ids}, options)
    end)
  end

  def remove_from_album(params, options \\ []) do
    UseCase.RemoveFromAlbum.execute(params, options)
  end
end
