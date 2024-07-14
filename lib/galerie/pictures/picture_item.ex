defmodule Galerie.Pictures.PictureItem do
  defstruct [
    :id,
    :name,
    :index,
    :folder_id,
    :group_name,
    :thumbnail,
    :datetime_original,
    :orientation,
    :inserted_at
  ]

  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureItem

  require Ecto.Query

  def from do
    Picture
    |> Ecto.Query.join(:left, [picture], metadata in assoc(picture, :picture_metadata),
      as: :metadata
    )
    |> Ecto.Query.select([picture, metadata: metadata], %PictureItem{
      id: picture.id,
      name: picture.name,
      folder_id: picture.folder_id,
      group_name: picture.group_name,
      thumbnail: picture.thumbnail,
      datetime_original: metadata.datetime_original,
      orientation: metadata.orientation,
      inserted_at: picture.inserted_at
    })
    |> Ecto.Query.where([picture], not is_nil(picture.thumbnail))
    |> Ecto.Query.distinct([picture], [picture.folder_id, picture.group_name])
  end

  def put_index(pictures) do
    Enum.with_index(pictures, &put_index/2)
  end

  def put_index(%PictureItem{} = picture, index) do
    %PictureItem{picture | index: index}
  end
end
