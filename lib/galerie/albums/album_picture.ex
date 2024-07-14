defmodule Galerie.Albums.AlbumPicture do
  use Galerie, :schema

  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPicture
  alias Galerie.Pictures.Picture

  schema("albums_pictures") do
    belongs_to(:album, Album)
    belongs_to(:picture, Picture)
  end

  @required ~w(album_id picture_id)a
  def changeset(%AlbumPicture{} = album_picture \\ %AlbumPicture{}, params) do
    album_picture
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
