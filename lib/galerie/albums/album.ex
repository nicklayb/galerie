defmodule Galerie.Albums.Album do
  use Galerie, :schema

  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumPictureGroup

  schema("albums") do
    field(:name, :string)

    field(:picture_count, :integer, virtual: true)

    belongs_to(:user, User)

    has_many(:albums_picture_groups, AlbumPictureGroup)
    has_many(:groups, through: [:albums_picture_groups, :group])
    has_many(:pictures, through: [:groups, :picture])
  end

  @required ~w(name user_id)a
  def changeset(%Album{} = album \\ %Album{}, params) do
    album
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
