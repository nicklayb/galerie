defmodule Galerie.Albums.Album do
  use Galerie, :schema

  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPicture

  schema("albums") do
    field(:name, :string)

    belongs_to(:user, User)

    has_many(:albums_pictures, AlbumPicture)
    has_many(:pictures, through: [:albums_pictures, :picture])
  end

  @required ~w(name user_id)a
  def changeset(%Album{} = album \\ %Album{}, params) do
    album
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
