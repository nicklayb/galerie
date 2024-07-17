defmodule Galerie.Pictures.PictureItem do
  defstruct [
    :id,
    :name,
    :index,
    :folder_id,
    :group_id,
    :group_name,
    :thumbnail,
    :datetime_original,
    :orientation,
    :main_picture_id,
    :inserted_at
  ]

  alias Galerie.Pictures.Picture.Group
  alias Galerie.Pictures.PictureItem

  require Ecto.Query

  def from do
    Group
    |> Ecto.Query.join(:inner, [group], picture in assoc(group, :main_picture), as: :picture)
    |> Ecto.Query.join(:left, [picture: picture], metadata in assoc(picture, :metadata),
      as: :metadata
    )
    |> Ecto.Query.select([group, picture: picture, metadata: metadata], %PictureItem{
      id: picture.id,
      name: picture.name,
      folder_id: picture.folder_id,
      group_id: group.id,
      group_name: group.group_name,
      thumbnail: picture.thumbnail,
      datetime_original: metadata.datetime_original,
      orientation: metadata.orientation,
      main_picture_id: group.main_picture_id,
      inserted_at: picture.inserted_at
    })
    |> Ecto.Query.where([picture: picture], not is_nil(picture.thumbnail))
    |> Ecto.Query.distinct([group, picture: picture], [picture.folder_id, group.group_name])
  end

  def put_index(pictures) do
    Enum.with_index(pictures, &put_index/2)
  end

  def put_index(%PictureItem{} = picture, index) do
    %PictureItem{picture | index: index}
  end
end
