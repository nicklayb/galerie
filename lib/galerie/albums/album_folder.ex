defmodule Galerie.Albums.AlbumFolder do
  use Galerie, :schema

  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumFolder
  alias Galerie.Accounts.User

  schema("album_folders") do
    field(:name, :string)

    belongs_to(:parent_folder, AlbumFolder)
    belongs_to(:user, User)

    has_many(:albums, Album)
  end

  @required ~w(user_id name)a
  @optional ~w(parent_folder_id)a
  @castable @required ++ @optional
  def changeset(%AlbumFolder{} = album_folder \\ %AlbumFolder{}, params) do
    album_folder
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.unique_constraint(:name, name: :album_folders_parent_folder_id_name_index)
  end
end
