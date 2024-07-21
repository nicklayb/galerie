defmodule Galerie.Albums.AlbumPictureGroup do
  use Galerie, :schema

  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Pictures.Picture.Group

  schema("albums_picture_groups") do
    belongs_to(:album, Album)
    belongs_to(:group, Group)

    timestamps()
  end

  @required ~w(album_id group_id)a
  def changeset(%AlbumPictureGroup{} = album_picture \\ %AlbumPictureGroup{}, params) do
    album_picture
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
