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
