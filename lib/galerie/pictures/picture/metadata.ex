defmodule Galerie.Pictures.Picture.Metadata do
  use Galerie, :schema
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Metadata

  @orientations ~w(landscape portrait square)a
  schema("picture_metadata") do
    field(:exposure_time, Galerie.Ecto.Types.Fraction)
    field(:f_number, :float)
    field(:lens_model, :string)
    field(:camera_make, :string)
    field(:camera_model, :string)
    field(:datetime_original, :naive_datetime)
    field(:longitude, :float)
    field(:latitude, :float)
    field(:width, :integer)
    field(:height, :integer)
    field(:rotation, :integer)
    field(:orientation, Ecto.Enum, values: @orientations)

    belongs_to(:picture, Picture)

    timestamps()
  end

  @required ~w(width height orientation picture_id)a
  @optional ~w(exposure_time f_number lens_model camera_make camera_model datetime_original longitude latitude rotation)a
  @castable @required ++ @optional
  def changeset(%Metadata{} = metadata \\ %Metadata{}, params) do
    metadata
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end
end
