defmodule Galerie.Albums.UseCase.RemoveAlbum do
  @moduledoc """
  Use case to remove an album. Since albums belongs to a given user,
  the user needs to provided as part of the options.
  """
  use Galerie.UseCase
  alias Galerie.Albums.Album

  @impl Galerie.UseCase
  def validate(album_id, options) do
    Galerie.Albums.get_album_belonging_to_user(album_id, Keyword.get(options, :user))
  end

  @impl Galerie.UseCase
  def run(multi, %Album{} = album, _options) do
    Ecto.Multi.delete(multi, :album, album)
  end

  @impl Galerie.UseCase
  def after_run(%{album: album}, _options) do
    Galerie.PubSub.broadcast({Galerie.Accounts.User, album.user_id}, {:album_deleted, album})
  end

  @impl Galerie.UseCase
  def return(%{album: album}, _options), do: album
end
