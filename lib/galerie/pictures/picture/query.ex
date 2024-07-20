defmodule Galerie.Pictures.Picture.Query do
  require Ecto.Query
  alias Galerie.Pictures.Picture

  def from, do: Ecto.Query.from(Picture, as: :picture)

  def by_fullpaths(query \\ from(), fullpath) do
    Ecto.Query.where(query, [picture: picture], picture.fullpath in ^List.wrap(fullpath))
  end

  def by_ids(query \\ from(), picture_ids) do
    Ecto.Query.where(query, [picture: picture], picture.id in ^List.wrap(picture_ids))
  end

  def by_group_id(query \\ from(), group_id) do
    Ecto.Query.where(query, [picture: picture], picture.group_id == ^group_id)
  end

  def ensure_joined(query, :metadata) do
    Galerie.Ecto.Query.join_once(query, :metadata, fn query ->
      Ecto.Query.join(query, :left, [picture: picture], metadata in assoc(picture, :metadata),
        as: :metadata
      )
    end)
  end
end
