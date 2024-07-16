defmodule Galerie.Pictures.Picture.Exif do
  use Galerie, :schema
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Exif

  schema("picture_exif") do
    field(:exif, :map)

    belongs_to(:picture, Picture)

    timestamps()
  end

  @required ~w(exif picture_id)a
  def changeset(%Exif{} = exif \\ %Exif{}, params) do
    exif
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
