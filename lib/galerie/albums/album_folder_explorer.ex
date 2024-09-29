defmodule Galerie.Albums.AlbumFolderExplorer do
  @behaviour Galerie.Explorer

  require Ecto.Query
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumFolder
  alias Galerie.Accounts.User
  alias Galerie.Repo

  @impl Galerie.Explorer
  def identity(%AlbumFolder{id: id}), do: id
  def identity(%Album{id: id}), do: id

  @impl Galerie.Explorer
  def children(%AlbumFolder{} = album_folder) do
    album_folder = Repo.preload(album_folder, [:folders, :albums])

    {album_folder, branches(album_folder.folders) ++ leaves(album_folder.albums)}
  end

  def children(%User{} = user) do
    album_folders =
      user
      |> Ecto.assoc(:album_folders)
      |> Ecto.Query.where([album_folder], is_nil(album_folder.parent_folder_id))
      |> Repo.all()

    albums =
      user
      |> Ecto.assoc(:albums)
      |> Ecto.Query.where([album], is_nil(album.album_folder_id))
      |> Repo.all()

    branches(album_folders) ++ leaves(albums)
  end

  defp branches(folders) do
    folders
    |> Enum.sort_by(& &1.name)
    |> Enum.map(&{:branch, &1})
  end

  defp leaves(albums) do
    albums
    |> Enum.sort_by(& &1.name)
    |> Enum.map(&{:leaf, &1})
  end
end
