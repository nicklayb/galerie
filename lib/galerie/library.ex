defmodule Galerie.Library do
  alias Galerie.Folder
  alias Galerie.Picture
  alias Galerie.Repo

  require Ecto.Query

  @spec list_pictures(Keyword.t()) :: Repo.Page.t()
  def list_pictures(_) do
    Picture
    |> Ecto.Query.order_by({:desc, :inserted_at})
    |> Ecto.Query.where([picture], not is_nil(picture.thumbnail))
    |> Repo.paginate(%{limit: 30, sort: {:desc, :inserted_at}})
  end

  @spec get_picture(String.t()) :: Result.t(Picture.t(), :not_found)
  def get_picture(picture_id) do
    Repo.fetch(Picture, picture_id)
  end

  @spec get_picture(String.t()) :: Result.t(Picture.t(), :not_found)
  def get_picture_by_path(path) do
    Repo.fetch_by(Picture, fullpath: path)
  end

  def get_or_create_folder!(folder_path) do
    case Repo.fetch_by(Folder, path: folder_path) do
      {:ok, %Folder{} = folder} ->
        folder

      _ ->
        %{path: folder_path}
        |> Folder.changeset()
        |> Repo.insert!()
    end
  end

  def list_imported_paths(picture_paths) do
    Picture
    |> Ecto.Query.where([picture], picture.fullpath in ^picture_paths)
    |> Ecto.Query.select([picture], picture.fullpath)
    |> Repo.all()
  end

  def picture_imported?(fullpath) do
    Picture
    |> Ecto.Query.where([picture], picture.fullpath == ^fullpath)
    |> Repo.exists?()
  end
end
