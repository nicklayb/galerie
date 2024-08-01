defmodule Galerie.Pictures.Picture.Group do
  use Galerie, :schema

  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group

  @rating_range 1..5

  schema("picture_groups") do
    field(:name, :string)
    field(:group_name, :string)
    field(:rating, :integer)

    belongs_to(:main_picture, Picture)
    belongs_to(:folder, Folder)

    has_many(:pictures, Picture)
    has_many(:albums_picture_groups, AlbumPictureGroup)

    timestamps()
  end

  @required ~w(name group_name folder_id)a
  @optional ~w(rating main_picture_id)a
  @castable @required ++ @optional
  def changeset(%Group{} = group \\ %Group{}, params) do
    group
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_inclusion(:rating, @rating_range)
  end

  @required ~w(main_picture_id)a
  def main_picture_changeset(%Group{} = group \\ %Group{}, params) do
    group
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end

  @doc "Gets available rating range"
  @spec rating_range() :: Range.t()
  def rating_range, do: @rating_range
end
