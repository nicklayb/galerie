defmodule Galerie.Pictures.Picture do
  use Galerie, :schema

  alias Galerie.Directory.FileName
  alias Galerie.Folders.Folder
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Exif
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Pictures.Picture.Metadata

  @type path_type :: :original | :jpeg

  @picture_types ~w(tiff jpeg)a

  schema("pictures") do
    field(:name, :string)
    field(:extension, :string)
    field(:original_name, :string)
    field(:fullpath, :string)
    field(:group_name, :string, virtual: true)
    field(:type, Ecto.Enum, values: @picture_types)
    field(:size, :integer)

    field(:converted_jpeg, :string)
    field(:thumbnail, :string)

    field(:index, :integer, virtual: true)
    field(:folder_path, :string, virtual: true)

    belongs_to(:folder, Folder)

    belongs_to(:group, Group)

    has_one(:exif, Exif)
    has_one(:metadata, Metadata)

    has_many(:albums, through: [:group, :albums_picture_groups, :album])

    timestamps()
  end

  @required_for_cast ~w(fullpath folder_id folder_path)a
  @castable @required_for_cast
  @required ~w(folder_id name extension original_name fullpath size)a
  @optional ~w(converted_jpeg group_id thumbnail)a
  def create_changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required_for_cast)
    |> Galerie.Ecto.Changeset.update_valid(&cast_parts/1)
    |> Ecto.Changeset.validate_required(@required)
  end

  @castable @required ++ @optional
  def changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end

  @required ~w(group_id)a
  def group_changeset(%Picture{} = picture \\ %Picture{}, params) do
    picture
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
  end

  defp cast_parts(%Ecto.Changeset{} = changeset) do
    fullpath = Ecto.Changeset.get_change(changeset, :fullpath)
    folder_path = Ecto.Changeset.get_change(changeset, :folder_path)

    %FileName{
      name: name,
      extension: extension,
      original_name: original_name,
      group_name: group_name
    } = FileName.cast(fullpath, folder_path)

    type = Pictures.file_type(fullpath)

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

  def path(%Picture{type: :jpeg, converted_jpeg: nil, fullpath: fullpath}, :jpeg), do: fullpath

  def path(%Picture{converted_jpeg: jpeg}, :jpeg), do: jpeg

  def rotation(%Picture{metadata: %Metadata{rotation: rotation}}), do: rotation

  def rotation(_), do: 0
end
