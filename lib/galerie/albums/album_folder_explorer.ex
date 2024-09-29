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
  def children(%AlbumFolder{} = album_folder, :branches) do
    branches(album_folder)
  end

  def children(%AlbumFolder{} = album_folder, :leaves) do
    leaves(album_folder)
  end

  def children(%User{} = user, :branches) do
    branches(user)
  end

  def children(%User{} = user, :leaves) do
    leaves(user)
  end

  defp branches(%User{} = user) do
    user
    |> Ecto.assoc(:album_folders)
    |> Ecto.Query.where([album_folder], is_nil(album_folder.parent_folder_id))
    |> Repo.all()
    |> branches()
  end

  defp branches(%AlbumFolder{} = album_folder) do
    album_folder = Repo.preload(album_folder, :folders)
    {album_folder, branches(album_folder.folders)}
  end

  defp branches(folders) do
    folders
    |> Enum.sort_by(& &1.name)
    |> Enum.map(&{:branch, &1})
  end

  defp leaves(%User{} = user) do
    user
    |> Ecto.assoc(:albums)
    |> Ecto.Query.where([album], is_nil(album.album_folder_id))
    |> Repo.all()
    |> leaves()
  end

  defp leaves(%AlbumFolder{} = album_folder) do
    album_folder = Repo.preload(album_folder, :albums)
    {album_folder, leaves(album_folder.albums)}
  end

  defp leaves(albums) do
    albums
    |> Enum.sort_by(& &1.name)
    |> Enum.map(&{:leaf, &1})
  end
end
