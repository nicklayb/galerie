defmodule GalerieWeb.Components.Modals.EditPictures.Form do
  use GalerieWeb.Form, name: :edit_pictures

  defform(Metadatas) do
    field(:exposure_time, Galerie.Ecto.Types.Fraction)
    field(:f_number, :float)
    field(:lens_model, :string)
    field(:camera_make, :string)
    field(:camera_model, :string)
    field(:focal_length, :float)
  after
    def changeset(%Metadatas{} = form \\ %Metadatas{}, params) do
      Ecto.Changeset.cast(form, params, form_keys(Metadatas))
    end
  end

  defform do
    field(:group_ids, {:array, :binary_id})
    field(:album_ids, {:array, :binary_id}, default: [])
    embeds_one(:metadatas, Metadatas)
  end

  def changeset(%Form{} = form \\ %Form{}, params) do
    form
    |> Ecto.Changeset.cast(params, form_keys(Form))
    |> Ecto.Changeset.cast_embed(:metadatas)
    |> Ecto.Changeset.validate_required([:group_ids])
  end
end

# defmodule GalerieWeb.Components.Modals.EditPictures.Form do
#   use Ecto.Schema
#
#   defmodule MetadataForm do
#     use Ecto.Schema
#
#     embedded_schema do
#     end
#   end
#
#   embedded_schema do
#     field(:group_ids, {:array, :binary_id})
#     field(:album_ids, {:array, :binary_id})
#     field(:metadata, MetadataForm)
#   end
#   @types %{
#     group_ids: {:array, :binary_id},
#     album_ids: {:array, :binary_id},
#     metadatas: 
#   }
#   @keys Map.keys(@types)
#   @data {%{album_ids: [], group_ids: [], metadatas: []}, @types}
#   def new(params \\ %{}) do
#     @data
#     |> Ecto.Changeset.cast(params, @keys)
#     |> Ecto.Changeset.validate_required(@keys)
#     |> Ecto.Changeset.validate_length(:group_ids, min: 1)
#     |> Phoenix.Component.to_form(as: :add_to_album)
#   end
#
#   def submit(%Phoenix.HTML.Form{source: source}), do: submit(source)
#
#   def submit(%Ecto.Changeset{} = changeset) do
#     Ecto.Changeset.apply_action(changeset, :insert)
#   end
# end
