defmodule Galerie.Library.PictureItem do
  defstruct [:name, :thumbnail, :picture_ids]

  alias Galerie.Library.PictureItem

  require Ecto.Query

  def from do
    Picture
    |> Ecto.Query.select([picture], %PictureItem{})
    |> Ecto.Query.group_by([picture], picture.name)
  end
end
