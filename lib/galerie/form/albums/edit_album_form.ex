defmodule Galerie.Form.Albums.EditAlbumForm do
  use Galerie.Form, name: :edit_album

  defform do
    field(:album_id, :binary_id)
    field(:name, :string)
  end

  def changeset(%EditAlbumForm{} = form \\ %EditAlbumForm{}, params) do
    keys = form_keys(EditAlbumForm)

    form
    |> Ecto.Changeset.cast(params, keys)
    |> Ecto.Changeset.validate_required(keys)
  end
end
