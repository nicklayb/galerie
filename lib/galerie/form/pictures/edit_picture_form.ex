defmodule Galerie.Form.Pictures.EditPicturesForm do
  use Galerie.Form, name: :edit_pictures

  defform(Metadatas) do
    @fields_with_types [
      exposure_time: Galerie.Ecto.Types.Fraction,
      f_number: :float,
      lens_model: :string,
      camera_make: :string,
      camera_model: :string,
      focal_length: :float
    ]
    @field_edited Enum.map(@fields_with_types, fn {key, _} -> :"#{key}_edited" end)
    @fields Keyword.keys(@fields_with_types)

    Enum.map(@fields_with_types, fn {key, type} -> field(key, type) end)
    Enum.map(@field_edited, &field(&1, :boolean))
  after
    def changeset(%Metadatas{} = form \\ %Metadatas{}, params) do
      edited_keys = edited_keys(form, params)

      Ecto.Changeset.cast(form, params, @field_edited ++ edited_keys)
    end

    def edited_metadata(%Metadatas{} = metadatas) do
      Enum.reduce(@field_edited, [], fn field, acc ->
        if Map.get(metadatas, field) == true do
          [edited_field_to_field(field) | acc]
        else
          acc
        end
      end)
    end

    defp edited_keys(form, params) do
      form
      |> Ecto.Changeset.cast(params, @field_edited)
      |> Map.get(:changes, %{})
      |> Enum.reduce([], fn {key, checked?}, acc ->
        if checked? do
          [edited_field_to_field(key) | acc]
        else
          acc
        end
      end)
    end

    defp edited_field_to_field(edited_field_key) do
      edited_field_key
      |> to_string()
      |> String.replace("_edited", "")
      |> String.to_existing_atom()
    end

    def text_inputs, do: @fields
  end

  defform do
    field(:group_ids, {:array, :binary_id})
    field(:album_ids, {:array, :binary_id}, default: [])
    embeds_one(:metadatas, Metadatas)
  end

  def changeset(%EditPicturesForm{} = form \\ %EditPicturesForm{}, params) do
    form
    |> Ecto.Changeset.cast(params, form_keys(EditPicturesForm))
    |> Ecto.Changeset.cast_embed(:metadatas)
    |> Ecto.Changeset.validate_required([:group_ids])
  end

  def post_submit(%EditPicturesForm{} = form) do
    %EditPicturesForm{
      form
      | group_ids: Enum.uniq(form.group_ids),
        album_ids: Enum.uniq(form.album_ids)
    }
  end
end
