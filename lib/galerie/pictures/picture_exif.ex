defmodule Galerie.Pictures.PictureExif do
  use Galerie, :schema
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureExif

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
