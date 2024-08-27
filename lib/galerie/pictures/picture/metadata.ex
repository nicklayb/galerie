defmodule Galerie.Pictures.Picture.Metadata do
  use Galerie, :schema
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Metadata

  @editable_metadata ~w(exposure_time f_number focal_length lens_model camera_make camera_model)a
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
    field(:focal_length, :float)
    field(:width, :integer)
    field(:height, :integer)
    field(:rotation, :integer)
    field(:orientation, Ecto.Enum, values: @orientations)
    field(:manually_updated_fields, Galerie.Ecto.Types.MapSet, type: :atom, default: MapSet.new())

    belongs_to(:picture, Picture)

    timestamps()
  end

  @required ~w(width height orientation picture_id)a
  @optional ~w(datetime_original longitude latitude rotation)a ++ @editable_metadata
  @castable @required ++ @optional
  def changeset(
        %Metadata{} = metadata \\ %Metadata{},
        params
      ) do
    castable = without_manually_updated_fields(metadata, @castable)
    required = without_manually_updated_fields(metadata, @required)

    metadata
    |> Ecto.Changeset.cast(params, castable)
    |> Ecto.Changeset.validate_required(required)
  end

  def manual_edit_changeset(%Metadata{} = metadata \\ %Metadata{}, params) do
    metadata
    |> Ecto.Changeset.cast(params, @editable_metadata)
    |> Galerie.Ecto.Changeset.update_valid(&update_manually_updated_fields/1)
  end

  defp update_manually_updated_fields(%Ecto.Changeset{changes: changes} = changeset) do
    manually_updated_fields =
      Enum.reduce(changes, Ecto.Changeset.get_field(changeset, :manually_updated_fields), fn
        {field, value}, acc when value in ["", nil] ->
          MapSet.delete(acc, field)

        {field, _}, acc ->
          MapSet.put(acc, field)
      end)

    Ecto.Changeset.cast(changeset, %{manually_updated_fields: manually_updated_fields}, [
      :manually_updated_fields
    ])
  end

  defp without_manually_updated_fields(
         %Metadata{manually_updated_fields: manually_updated_fields},
         fields
       ) do
    Enum.reject(fields, &(&1 in manually_updated_fields))
  end
end
