defmodule GalerieWeb.Components.Modals.AddToAlbum.Form do
  @types %{
    group_ids: {:array, :binary_id},
    album_ids: {:array, :binary_id}
  }
  @keys Map.keys(@types)
  @data {%{album_ids: [], group_ids: []}, @types}
  def new(params \\ %{}) do
    @data
    |> Ecto.Changeset.cast(params, @keys)
    |> Ecto.Changeset.validate_required(@keys)
    |> Ecto.Changeset.validate_length(:group_ids, min: 1)
    |> Phoenix.Component.to_form(as: :add_to_album)
  end

  def submit(%Phoenix.HTML.Form{source: source}), do: submit(source)

  def submit(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.apply_action(changeset, :insert)
  end
end
