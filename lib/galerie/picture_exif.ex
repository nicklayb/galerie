defmodule Galerie.PictureExif do
  use Ecto.Schema
  alias Galerie.Picture
  alias Galerie.PictureExif

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("picture_exif") do
    field(:exif, :map)

    belongs_to(:picture, Picture)

    timestamps()
  end

  @required ~w(exif picture_id)a
  def changeset(%PictureExif{} = picture_exif \\ %PictureExif{}, params) do
    picture_exif
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
