defmodule Galerie.Pictures do
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.PictureItem
  alias Galerie.Pictures.UseCase
  alias Galerie.Repo

  require Ecto.Query

  @file_types [tiff: &ExifParser.parse_tiff_file/1, jpeg: &Image.open/1]

  @spec valid_file_type?(String.t()) :: boolean()
  def valid_file_type?(fullpath) do
    fullpath
    |> file_type()
    |> then(&(not is_nil(&1)))
  end

  @spec file_type(String.t()) :: Picture.file_type() | nil
  def file_type(fullpath) do
    Enum.find_value(@file_types, fn {type, function} ->
      case function.(fullpath) do
        {:ok, _} -> type
        _ -> nil
      end
    end)
  end

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
    group_id
    |> Picture.Query.by_group_id()
    |> Picture.Query.ensure_joined(:metadata)
    |> Ecto.Query.preload([picture, metadata: metadata], metadata: metadata)
  end

  @spec get_all_pictures([String.t()]) :: [Picture.t()]
  def get_all_pictures(picture_ids) do
    picture_ids
    |> Picture.Query.by_ids()
    |> Repo.all()
  end

  @default_limit 40
  @spec list_pictures([String.t()], Keyword.t()) :: Repo.Page.t()
  def list_pictures(folder_ids, options \\ []) do
    {limit, options} = Keyword.pop(options, :limit, @default_limit)

    folder_ids
    |> PictureItem.by_folder_ids()
    |> Ecto.Query.order_by(
      [metadata: metadata],
      {:desc, metadata.datetime_original}
    )
    |> apply_pictures_filter(options)
    |> Repo.paginate(%{limit: limit, sort_by: {:desc, :datetime_original}})
  end

  def get_picture_item(:group_id, group_id) do
    group_id
    |> PictureItem.by_group_ids()
    |> Repo.one()
  end

  defp apply_pictures_filter(query, options) do
    Enum.reduce(options, query, fn
      {:album_ids, album_ids}, acc ->
        PictureItem.by_album_ids(acc, album_ids)

      {:rating, {0, 5}}, acc ->
        acc

      {:rating, {minimum, maximum}}, acc ->
        PictureItem.by_rating(acc, minimum, maximum)

      _, acc ->
        acc
    end)
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
    picture_paths
    |> Picture.Query.by_fullpaths()
    |> Ecto.Query.select([picture], picture.fullpath)
    |> Repo.all()
  end

  def picture_imported?(fullpath) do
    fullpath
    |> Picture.Query.by_fullpaths()
    |> Repo.exists?()
  end

  # TODO: Cache the function below
  def get_picture_path(picture_id, :original) do
    picture_id
    |> Picture.Query.by_ids()
    |> Ecto.Query.select([picture], picture.fullpath)
    |> Repo.fetch_one()
  end

  def get_picture_path(picture_id, :thumb) do
    picture_id
    |> Picture.Query.by_ids()
    |> Ecto.Query.select([picture], picture.thumbnail)
    |> Repo.fetch_one()
  end

  def get_picture_path(picture_id, :jpeg) do
    picture_id
    |> Picture.Query.by_ids()
    |> Ecto.Query.select([picture], {picture.type, picture.fullpath, picture.converted_jpeg})
    |> Repo.fetch_one()
    |> Result.map(fn
      {:tiff, _, converted_jpeg} -> converted_jpeg
      {:jpeg, fullpath, _} -> fullpath
    end)
  end

  def insert_picture(params, options \\ []) do
    UseCase.InsertPicture.execute(params, options)
  end

  def update_rating(group_id, rating, options \\ []) do
    UseCase.UpdateRating.execute(%{group_id: group_id, rating: rating}, options)
  end

  def reload_picture_item(%PictureItem{group_id: group_id}) do
    PictureItem.from()
    |> PictureItem.by_group_ids(group_id)
    |> Repo.one()
  end
end
