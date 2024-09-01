defmodule Galerie.Albums.Album do
  @moduledoc """
  Album schema. The albums are related to Picture.Group since
  we want all child pictures to be part of the album at once.
  """
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

    timestamps()
  end

  @required ~w(name user_id)a
  @doc """
  Album insert or update changeset.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%Album{} = album \\ %Album{}, params) do
    album
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.unique_constraint(:name, name: :albums_user_id_name_index)
  end
end
