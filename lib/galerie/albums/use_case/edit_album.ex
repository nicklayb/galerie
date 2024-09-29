defmodule Galerie.Albums.UseCase.EditAlbum do
  @moduledoc """
  Use case to edit an album. Since albums belongs to a given user,
  the user needs to provided as part of the options.
  """
  use Galerie.UseCase
  alias Galerie.Albums.Album

  alias Galerie.Form.Albums.EditAlbumForm

  @impl Galerie.UseCase
  def validate(%EditAlbumForm{id: album_id} = form, options) do
    with {:ok, %Album{} = album} <-
           Galerie.Albums.get_album_belonging_to_user(album_id, Keyword.get(options, :user)) do
      {:ok, {form, album}}
    end
  end

  @impl Galerie.UseCase
  def run(multi, {%EditAlbumForm{} = form, %Album{} = album}, _options) do
    Ecto.Multi.update(
      multi,
      :album,
      Album.changeset(album, Map.from_struct(form))
    )
  end

  @impl Galerie.UseCase
  def after_run(%{album: album}, _options) do
    Galerie.PubSub.broadcast({Galerie.Accounts.User, album.user_id}, {:album_updated, album})
  end

  @impl Galerie.UseCase
  def return(%{album: album}, _options), do: album
end
