defmodule Galerie.Pictures do
  alias Galerie.Folder
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureItem
  alias Galerie.Repo

  require Ecto.Query

  def get_grouped_pictures(%PictureItem{} = picture_item) do
    picture_item
    |> grouped_pictures_query()
    |> Repo.all()
  end

  def get_grouped_picture(%PictureItem{} = picture_item) do
    picture_item
    |> grouped_pictures_query()
    |> Repo.first()
  end

  defp grouped_pictures_query(%PictureItem{folder_id: folder_id, group_name: group_name}) do
    Picture
    |> Ecto.Query.where(
      [picture],
      picture.folder_id == ^folder_id and picture.group_name == ^group_name
    )
    |> Ecto.Query.join(:left, [picture], metadata in assoc(picture, :picture_metadata),
      as: :metadata
    )
    |> Ecto.Query.preload([picture, metadata: metadata], picture_metadata: metadata)
  end

  @spec get_all_pictures([String.t()]) :: [Picture.t()]
  def get_all_pictures(picture_ids) do
    Picture
    |> Ecto.Query.where([picture], picture.id in ^picture_ids)
    |> Repo.all()
  end

  @default_limit 16
  @spec list_pictures(Keyword.t()) :: Repo.Page.t()
  def list_pictures(options \\ []) do
    limit = Keyword.get(options, :limit, @default_limit)

    PictureItem.from()
    |> Ecto.Query.order_by(
      [picture_item, metadata: metadata],
      {:desc, metadata.datetime_original}
    )
    |> Repo.paginate(%{limit: limit, sort_by: {:desc, :datetime_original}})
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

  # TODO: Cache the function below
  def get_picture_path(picture_id, :original) do
    picture_id
    |> base_picture_path_query()
    |> Ecto.Query.select([picture], picture.fullpath)
    |> Repo.fetch_one()
  end

  def get_picture_path(picture_id, :thumb) do
    picture_id
    |> base_picture_path_query()
    |> Ecto.Query.select([picture], picture.thumbnail)
    |> Repo.fetch_one()
  end

  def get_picture_path(picture_id, :jpeg) do
    picture_id
    |> base_picture_path_query()
    |> Ecto.Query.select([picture], {picture.type, picture.fullpath, picture.converted_jpeg})
    |> Repo.fetch_one()
    |> Result.map(fn
      {:tiff, _, converted_jpeg} -> converted_jpeg
      {:jpeg, fullpath, _} -> fullpath
    end)
  end

  defp base_picture_path_query(query \\ Picture, picture_id) do
    Ecto.Query.where(query, [picture], picture.id == ^picture_id)
  end
end
