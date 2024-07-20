defmodule Galerie.Folders.Folder do
  use Galerie, :schema

  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture

  schema("folders") do
    field(:path, :string)

    belongs_to(:user, User)

    has_many(:pictures, Picture)

    timestamps()
  end

  @required ~w(path)a
  @optional ~w(user_id)a
  @castable @required ++ @optional
  def changeset(%Folder{} = folder \\ %Folder{}, params) do
    folder
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end
end
