defmodule Galerie.Pictures do
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

  defp grouped_pictures_query(%PictureItem{group_id: group_id}) do
    Picture
    |> Ecto.Query.where([picture], picture.group_id == ^group_id)
    |> Ecto.Query.join(:left, [picture], metadata in assoc(picture, :metadata), as: :metadata)
    |> Ecto.Query.preload([picture, metadata: metadata], metadata: metadata)
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
      [metadata: metadata],
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
