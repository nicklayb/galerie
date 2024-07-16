defmodule Galerie.Pictures.PictureGroup do
  use Galerie, :schema

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureGroup

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
  def changeset(%PictureGroup{} = picture_group \\ %PictureGroup{}, params) do
    picture_group
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end
end
