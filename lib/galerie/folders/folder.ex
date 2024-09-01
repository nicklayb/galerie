defmodule Galerie.Folders.Folder do
  @moduledoc """
  Folder where pictures are getting stored. There is two
  types of folders:

  - *Global*: Folders that are local and sourced from file watcher
  - *User*: User's individual folders for uploaded pictures.

  A `Folder` with `user_id = nil` is considered *global*.
  """
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
  @doc """
  Folder changeset for creation. This changeset shouldn't be used
  for manual edition as they can create problems in the way file
  are sourced and could also lead to owner swap.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%Folder{} = folder \\ %Folder{}, params) do
    folder
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end
end
