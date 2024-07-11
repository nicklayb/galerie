defmodule Galerie.PictureMetadata do
  use Ecto.Schema
  alias Galerie.Picture
  alias Galerie.PictureMetadata

  @orientations ~w(landscape portrait square)a
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("picture_metadata") do
    field(:exposure_time, :float)
    field(:f_number, :float)
    field(:lens_model, :string)
    field(:camera_make, :string)
    field(:camera_model, :string)
    field(:datetime_original, :naive_datetime)
    field(:longitude, :float)
    field(:latitude, :float)
    field(:width, :integer)
    field(:height, :integer)
    field(:orientation, Ecto.Enum, values: @orientations)

    belongs_to(:picture, Picture)

    timestamps()
  end

  @required ~w(width height orientation picture_id)a
  @optional ~w(exposure_time f_number lens_model camera_make camera_model datetime_original longitude latitude)a
  @castable @required ++ @optional
  def changeset(%PictureMetadata{} = picture_metadata \\ %PictureMetadata{}, params) do
    picture_metadata
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end
end
