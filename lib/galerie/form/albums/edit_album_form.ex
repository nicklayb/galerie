defmodule Galerie.Form.Albums.EditAlbumForm do
  use Galerie.Form, name: :edit_album

  defform do
    field(:id, :binary_id)
    field(:name, :string)
    field(:hide_from_main_library, :boolean, default: false)
  end

  def changeset(%EditAlbumForm{} = form \\ %EditAlbumForm{}, params) do
    keys = form_keys(EditAlbumForm)

    form
    |> Ecto.Changeset.cast(params, keys)
    |> Ecto.Changeset.validate_required(keys)
  end
end
