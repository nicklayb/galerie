defmodule Galerie.Pictures do
  alias Galerie.Pictures.PictureGroupsPerDate
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

  @metadata_filter ~w(camera_model lens_model f_number exposure_time focal_length)a
  defp apply_pictures_filter(query, options) do
    Enum.reduce(options, query, fn
      {:album_ids, album_ids}, acc ->
        PictureItem.by_album_ids(acc, album_ids)

      {:rating, ratings}, acc ->
        PictureItem.by_rating(acc, ratings)

      {:dates, dates}, acc ->
        PictureItem.by_dates(acc, dates)

      {metadata_filter, value}, acc when metadata_filter in @metadata_filter ->
        PictureItem.by_metadata(acc, metadata_filter, value)

      _, acc ->
        acc
    end)
  end

  @spec get_picture(String.t()) :: Box.Result.t(Picture.t(), :not_found)
  def get_picture(picture_id) do
    Repo.fetch(Picture, picture_id)
  end

  @spec get_picture_by_path(String.t()) :: Box.Result.t(Picture.t(), :not_found)
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
    |> Box.Result.map(fn
      {:tiff, _, converted_jpeg} -> converted_jpeg
      {:jpeg, fullpath, _} -> fullpath
    end)
  end

  def insert_picture(params, options \\ []) do
    Galerie.UseCase.execute(UseCase.InsertPicture, params, options)
  end

  def update_rating(group_id, rating, options \\ []) do
    Galerie.UseCase.execute(UseCase.UpdateRating, %{group_id: group_id, rating: rating}, options)
  end

  def reload_picture_item(%PictureItem{group_id: group_id}) do
    PictureItem.from()
    |> PictureItem.by_group_ids(group_id)
    |> Repo.one()
  end

  def distinct_metadata(metadata) do
    Picture.Metadata
    |> Ecto.Query.select([m], field(m, ^metadata))
    |> Ecto.Query.distinct(true)
    |> Ecto.Query.order_by([m], {:asc, ^metadata})
    |> Repo.all()
  end

  def update_metadata_manually(group_id, params, options \\ []) do
    Galerie.UseCase.execute(
      UseCase.UpdateMetadataManually,
      %{group_id: group_id, params: params},
      options
    )
  end

  def picture_groups_per_date(folder_id, date) do
    PictureGroupsPerDate
    |> Ecto.Query.where(
      [picture_groups_per_date],
      picture_groups_per_date.folder_id in ^List.wrap(folder_id)
    )
    |> Ecto.Query.group_by([picture_groups_per_date], picture_groups_per_date.date)
    |> Ecto.Query.select(
      [picture_groups_per_date],
      {picture_groups_per_date.date, sum(picture_groups_per_date.count)}
    )
    |> then(fn query ->
      if is_nil(date) do
        query
      else
        Ecto.Query.where(
          query,
          [picture_groups_per_date],
          picture_groups_per_date.date == ^date
        )
      end
    end)
    |> Repo.all()
  end

  def count_per_date(folder_id, date) do
    Ecto.Query.from(group in Picture.Group, as: :group)
    |> Ecto.Query.join(:inner, [group: group], main_picture in assoc(group, :main_picture),
      as: :main_picture
    )
    |> Ecto.Query.join(
      :inner,
      [main_picture: main_picture],
      metadata in assoc(main_picture, :metadata),
      as: :metadata
    )
    |> Ecto.Query.where([group: group], group.folder_id in ^List.wrap(folder_id))
    |> maybe_filter_by_date(date)
    |> Ecto.Query.group_by([metadata: metadata], type(metadata.datetime_original, :date))
    |> Ecto.Query.select(
      [group: group, metadata: metadata],
      {type(metadata.datetime_original, :date), count(group.id)}
    )
    |> Repo.all()
    |> Enum.into(%{})
    |> maybe_put_default(date)
  end

  defp maybe_put_default(map, nil), do: map

  defp maybe_put_default(map, date) do
    Map.put_new(map, date, 0)
  end

  defp maybe_filter_by_date(query, nil), do: query

  defp maybe_filter_by_date(query, %Date{} = date) do
    Ecto.Query.where(
      query,
      [metadata: metadata],
      type(metadata.datetime_original, :date) == ^date
    )
  end
end
