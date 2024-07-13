defmodule Galerie.Album do
  use Ecto.Schema

  alias Galerie.Album
  alias Galerie.Picture
  alias Galerie.User

  schema("albums") do
    field(:name, :string)

    belongs_to(:user, User)

    many_to_many(:pictures, Picture, join_through: "albums_pictures")
  end

  @required ~w(name user_id)a
  def changeset(%Album{} = album \\ %Album{}, params) do
    album
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
