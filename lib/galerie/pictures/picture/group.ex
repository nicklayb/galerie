defmodule Galerie.Pictures.Picture.Group do
  use Galerie, :schema

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group

  schema("picture_groups") do
    field(:name, :string)
    field(:group_name, :string)

    belongs_to(:main_picture, Picture)
    belongs_to(:folder, Folder)

    has_many(:pictures, Picture)

    timestamps()
  end

  @required ~w(name group_name folder_id)a
  @optional ~w(main_picture_id)a
  @castable @required ++ @optional
  def changeset(%Group{} = group \\ %Group{}, params) do
    group
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end

  @required ~w(main_picture_id)a
  def main_picture_changeset(%Group{} = group \\ %Group{}, params) do
    group
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end