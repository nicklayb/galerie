defmodule Galerie.Library.PictureItem do
  defstruct [:name, :thumbnail, :datetime_original, :inserted_at]

  alias Galerie.Picture
  alias Galerie.Library.PictureItem

  require Ecto.Query

  def from do
    Picture
    |> Ecto.Query.join(:left, [picture], metadata in assoc(picture, :picture_metadata),
      as: :metadata
    )
    |> Ecto.Query.select([picture, metadata: metadata], %PictureItem{
      name: picture.group_name,
      thumbnail: picture.thumbnail,
      datetime_original: metadata.datetime_original,
      inserted_at: picture.inserted_at
    })
    |> Ecto.Query.distinct([picture], picture.group_name)
  end
end
