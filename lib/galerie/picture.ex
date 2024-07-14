defmodule Galerie.Picture do
  use Ecto.Schema

  alias Galerie.Album
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
    field(:group_name, :string)
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

    many_to_many(:albums, Album, join_through: "albums_pictures")

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

    %{
      name: name,
      type: type,
      extension: extension,
      original_name: original_name,
      group_name: group_name
    } =
      extract_parts(fullpath, folder_path)

    %File.Stat{size: file_size} = File.stat!(fullpath)

    Ecto.Changeset.change(changeset, %{
      name: name,
      extension: extension,
      original_name: original_name,
      type: type,
      size: file_size,
      group_name: group_name
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

    group_name =
      String.trim_trailing(original_name, "." <> extension)

    type = extract_type(path)

    %{
      extension: extension,
      original_name: original_name,
      name: String.replace(filename, ".#{extension}", ""),
      type: type,
      group_name: group_name
    }
  end

  defp extract_type(path) do
    {key, _} =
      Enum.find(
        [tiff: &ExifParser.parse_tiff_file/1, jpeg: &Image.open/1],
        fn {_, function} ->
          path
          |> then(function)
          |> Result.succeeded?()
        end
      )

    key
  end

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

  def rotation(%Picture{picture_exif: %PictureExif{exif: %{"orientation" => orientation}}}) do
    cond do
      orientation =~ "90" -> 90
      orientation =~ "180" -> 180
      orientation =~ "270" -> 270
      true -> 0
    end
  end

  def rotation(_), do: 0
end
