defmodule Galerie.Folders.Folder do
  use Galerie, :schema

  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture

  schema("folders") do
    field(:path, :string)

    has_many(:pictures, Picture)

    timestamps()
  end

  @required ~w(path)a
  def changeset(%Folder{} = folder \\ %Folder{}, params) do
    folder
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end
end
