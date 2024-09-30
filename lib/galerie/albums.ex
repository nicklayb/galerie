defmodule Galerie.Albums do
  require Ecto.Query
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Albums.AlbumFolder
  alias Galerie.Albums.AlbumFolderExplorer
  alias Galerie.Albums.UseCase
  alias Galerie.Pictures.Picture
  alias Galerie.Repo

  @type picture_or_id :: Picture.t() | String.t()
  @type picture_or_pictures :: picture_or_id() | [picture_or_id()]

  def get_user_albums(%User{id: user_id}), do: get_user_albums(user_id)

  def get_user_albums(user_id) do
    user_id
    |> Album.Query.by_user()
    |> Album.Query.with_picture_count()
    |> Ecto.Query.order_by([album: album], {:desc, album.updated_at})
    |> Repo.all()
    |> Enum.map(&with_folder_path/1)
  end

  defp with_folder_path(%Album{} = album) do
    folder_path = album_folder_path(album)
    %Album{album | folder_path: folder_path}
  end

  def album_folder_path(%Album{album_folder_id: nil} = album), do: [album]
  def album_folder_path(%AlbumFolder{parent_folder_id: nil} = album_folder), do: [album_folder]

  def album_folder_path(%Album{} = album) do
    parent_folder =
      album
      |> Ecto.assoc(:album_folder)
      |> Repo.one()

    [album | album_folder_path(parent_folder)]
  end

  def album_folder_path(%AlbumFolder{} = album_folder) do
    parent_folder =
      album_folder
      |> Ecto.assoc(:parent_folder)
      |> Repo.one()

    [album_folder | album_folder_path(parent_folder)]
  end

  def attach_picture_groups_to_albums(album_ids, group_ids, options \\ []) do
    album_ids
    |> Album.Query.by_ids()
    |> Repo.all()
    |> Enum.map(fn %Album{} = album ->
      UseCase.AddToAlbum.execute({album, group_ids}, options)
    end)
  end

  def remove_from_album(params, options \\ []) do
    UseCase.RemoveFromAlbum.execute(params, options)
  end

  def get_album_folder_belonging_to_user(album_folder_id, %User{id: user_id}) do
    case Repo.fetch(AlbumFolder, album_folder_id) do
      {:ok, %AlbumFolder{user_id: ^user_id} = album_folder} ->
        {:ok, album_folder}

      {:ok, %AlbumFolder{}} ->
        {:error, :unauthorized}

      error ->
        error
    end
  end

  def get_album_folder_belonging_to_user(_album_folder_id, _), do: {:error, :unauthorized}

  def get_album_belonging_to_user(album_id, %User{id: user_id}) do
    case Repo.fetch(Album, album_id) do
      {:ok, %Album{user_id: ^user_id} = album} ->
        {:ok, album}

      {:ok, %Album{}} ->
        {:error, :unauthorized}

      error ->
        error
    end
  end

  def get_album_belonging_to_user(_album_id, _), do: {:error, :unauthorized}

  def user_album_folders(%User{id: user_id}), do: user_album_folders(user_id)

  def user_album_folders(user_id) do
    {root_folders, nested_folders} =
      AlbumFolder
      |> Ecto.Query.where([album_folder], album_folder.user_id == ^user_id)
      |> Repo.all()
      |> Enum.split_with(&is_nil(&1.parent_folder_id))

    nested_folders_by_parent_id = Enum.group_by(nested_folders, & &1.parent_folder_id)

    root_folders
    |> build_tree(nested_folders_by_parent_id, &{&1.id, &1.name})
    |> flatten_tree()
  end

  defp flatten_tree(items, root \\ []) do
    Enum.flat_map(items, fn {{id, item}, nested} ->
      new_root = root ++ [item]
      [{id, new_root} | flatten_tree(nested, new_root)]
    end)
  end

  defp build_tree(root_folders, nested_folders, mapper) do
    Enum.map(root_folders, fn root_folder ->
      child_folders = Map.get(nested_folders, root_folder.id, [])

      mapped_root_folder = mapper.(root_folder)

      child_folders = build_tree(child_folders, nested_folders, mapper)
      {mapped_root_folder, child_folders}
    end)
  end

  def explore_user_albums(%User{} = user) do
    folders = AlbumFolderExplorer.children(user, :branches)
    albums = AlbumFolderExplorer.children(user, :leaves)
    Galerie.Explorer.new(AlbumFolderExplorer, folders ++ albums)
  end
end
