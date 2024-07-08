defmodule Galerie.Folder do
  use Ecto.Schema

  alias Galerie.Folder
  alias Galerie.Picture

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
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
