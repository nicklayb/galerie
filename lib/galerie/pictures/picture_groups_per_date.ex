defmodule Galerie.Pictures.PictureGroupsPerDate do
  use Galerie, :schema

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.PictureGroupsPerDate

  schema("picture_groupes_per_date") do
    field(:date, :date)
    field(:count, :integer)

    belongs_to(:folder, Folder)

    timestamps()
  end

  @required ~w(date folder_id count)a
  @castable @required
  def changeset(
        %PictureGroupsPerDate{} = picture_groups_per_date \\ %PictureGroupsPerDate{},
        params
      ) do
    picture_groups_per_date
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_number(:count, greater_than: 0)
  end
end
