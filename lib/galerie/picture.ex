defmodule Galerie.Picture do
  use Ecto.Schema
  alias Galerie.Picture
  alias Galerie.PictureExif
  alias Galerie.PictureMetadata

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

    has_one(:picture_exif, PictureExif)
    has_one(:picture_metadata, PictureMetadata)

    timestamps()
  end

  @required ~w(name extension original_name fullpath size)a
  @optional ~w(converted_jpeg thumbnail)a
  def create_changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, [:fullpath])
    |> cast_parts()
    |> Ecto.Changeset.validate_required(@required)
  end

  @castable @required ++ @optional
  def changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end

  defp cast_parts(%Ecto.Changeset{} = changeset) do
    case Ecto.Changeset.get_change(changeset, :fullpath) do
      nil ->
        changeset

      path ->
        %{name: name, type: type, extension: extension, original_name: original_name} =
          extract_parts(path)

        %File.Stat{size: file_size} = File.stat!(path)

        changeset
        |> Ecto.Changeset.change(%{
          name: name,
          extension: extension,
          original_name: original_name,
          type: type
        })
        |> Ecto.Changeset.change(%{size: file_size})
    end
  end

  defp extract_parts(path) do
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
      original_name: filename,
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
end
