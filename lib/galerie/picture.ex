defmodule Galerie.Picture do
  use Ecto.Schema
  alias Galerie.Folder
  alias Galerie.Picture
  alias Galerie.PictureExif
  alias Galerie.PictureMetadata
  alias Galerie.User

  @type t :: %Picture{}
  @type path_type :: :original | :jpeg

  @picture_types ~w(tiff jpeg)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("pictures") do
    field(:name, :string)
    field(:extension, :string)
    field(:original_name, :string)
    field(:fullpath, :string)
    field(:type, Ecto.Enum, values: @picture_types)
    field(:size, :integer)

    field(:converted_jpeg, :string)
    field(:thumbnail, :string)

    field(:index, :integer, virtual: true)
    field(:folder_path, :string, virtual: true)

    belongs_to(:folder, Folder)
    belongs_to(:user, User)

    has_one(:picture_exif, PictureExif)
    has_one(:picture_metadata, PictureMetadata)

    timestamps()
  end

  @required_for_cast ~w(fullpath folder_id folder_path)a
  @optional_for_cast ~w(user_id)a
  @castable @required_for_cast ++ @optional_for_cast
  @required ~w(folder_id name extension original_name fullpath size)a
  @optional ~w(converted_jpeg thumbnail)a
  def create_changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required_for_cast)
    |> cast_parts()
    |> Ecto.Changeset.validate_required(@required)
  end

  @castable @required ++ @optional
  def changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end

  defp cast_parts(%Ecto.Changeset{valid?: true} = changeset) do
    fullpath = Ecto.Changeset.get_change(changeset, :fullpath)
    folder_path = Ecto.Changeset.get_change(changeset, :folder_path)

    %{name: name, type: type, extension: extension, original_name: original_name} =
      extract_parts(fullpath, folder_path)

    %File.Stat{size: file_size} = File.stat!(fullpath)

    Ecto.Changeset.change(changeset, %{
      name: name,
      extension: extension,
      original_name: original_name,
      type: type,
      size: file_size
    })
  end

  defp cast_parts(%Ecto.Changeset{} = changeset), do: changeset

  defp extract_parts(path, folder_path) do
    original_name =
      path
      |> String.replace(folder_path, "", global: false)
      |> String.trim_leading("/")

    [filename | _] =
      path
      |> Path.split()
      |> Enum.reverse()

    [extension | _] =
      filename
      |> String.split(".")
      |> Enum.reverse()

    type = extract_type(path)

    %{
      extension: extension,
      original_name: original_name,
      name: String.replace(filename, ".#{extension}", ""),
      type: type
    }
  end

  defp extract_type(path) do
    {key, _} =
      Enum.find(
        [tiff: &ExifParser.parse_tiff_file/1, jpeg: &ExifParser.parse_jpeg_file/1],
        fn {_, function} ->
          path
          |> then(function)
          |> Result.succeeded?()
        end
      )

    key
  end

  def jpeg_path(%Picture{type: :tiff, converted_jpeg: converted_jpeg})
      when is_binary(converted_jpeg),
      do: {:ok, converted_jpeg}

  def jpeg_path(%Picture{type: :tiff}), do: {:error, :no_jpeg_available}
  def jpeg_path(%Picture{fullpath: fullpath}), do: {:ok, fullpath}

  def put_index(pictures) do
    Enum.with_index(pictures, &put_index/2)
  end

  def put_index(%Picture{} = picture, index) do
    %Picture{picture | index: index}
  end

  @spec path(t(), path_type()) :: String.t()
  def path(%Picture{fullpath: fullpath}, :original) do
    fullpath
  end

  def path(%Picture{type: :jpeg, fullpath: fullpath}, :jpeg), do: fullpath

  def path(%Picture{type: :tiff, converted_jpeg: jpeg}, :jpeg), do: jpeg
end
