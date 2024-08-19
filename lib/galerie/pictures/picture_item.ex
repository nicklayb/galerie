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
    :rating,
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
      name: picture.original_name,
      folder_id: picture.folder_id,
      group_id: group.id,
      group_name: group.group_name,
      thumbnail: picture.thumbnail,
      datetime_original: metadata.datetime_original,
      orientation: metadata.orientation,
      rating: group.rating,
      main_picture_id: group.main_picture_id,
      inserted_at: picture.inserted_at
    })
    |> Ecto.Query.where([picture: picture], not is_nil(picture.thumbnail))
  end

  def by_group_ids(query \\ from(), group_ids) do
    Ecto.Query.where(query, [group], group.id in ^List.wrap(group_ids))
  end

  def by_folder_ids(query \\ from(), folder_ids) do
    Ecto.Query.where(query, [group], group.folder_id in ^folder_ids)
  end

  def by_album_ids(query \\ from(), album_ids)
  def by_album_ids(query, []), do: query

  def by_album_ids(query, album_ids) do
    query
    |> ensure_joined(:album_picture_groups)
    |> Ecto.Query.where(
      [albums_picture_groups: albums_picture_groups],
      albums_picture_groups.album_id in ^album_ids
    )
  end

  def by_metadata(query, _, []), do: query

  def by_metadata(query, :exposure_time, values) do
    or_where =
      Enum.reduce(values, Ecto.Query.dynamic(false), fn %Fraction{
                                                          numerator: numerator,
                                                          denominator: denominator
                                                        },
                                                        acc ->
        Ecto.Query.dynamic(
          [metadata: metadata],
          ^acc or
            (fragment("(?).numerator", metadata.exposure_time) == ^numerator and
               fragment("(?).denominator", metadata.exposure_time) == ^denominator)
        )
      end)

    Ecto.Query.where(query, ^or_where)
  end

  def by_metadata(query, metadata, values) do
    Ecto.Query.where(query, [metadata: metadata], field(metadata, ^metadata) in ^values)
  end

  def by_rating(query, ratings) do
    case Enum.split_with(ratings, &(&1 == :empty)) do
      {[], []} ->
        query

      {[], ratings} ->
        Ecto.Query.where(query, [q], q.rating in ^ratings)

      {[:empty], ratings} ->
        Ecto.Query.where(query, [q], is_nil(q.rating) or q.rating in ^ratings)
    end
  end

  defp ensure_joined(query, :album_picture_groups) do
    Galerie.Ecto.Query.join_once(query, :album_picture_groups, fn query ->
      Ecto.Query.join(
        query,
        :left,
        [group],
        album_picture_group in assoc(group, :albums_picture_groups),
        as: :albums_picture_groups
      )
    end)
  end

  def put_index(pictures) do
    Enum.with_index(pictures, &put_index/2)
  end

  def put_index(%PictureItem{} = picture, index) do
    %PictureItem{picture | index: index}
  end
end
