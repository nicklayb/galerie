defmodule Galerie.Albums.UseCase.CreateAlbum do
  use Galerie.UseCase
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album

  @impl Galerie.UseCase
  def validate({%User{id: user_id}, params}, options), do: validate({user_id, params}, options)

  def validate({user_id, params}, _options) do
    {:ok, Map.Extra.put(params, :user_id, user_id)}
  end

  @impl Galerie.UseCase
  def run(multi, params, _options) do
    Ecto.Multi.insert(multi, :album, Album.changeset(params))
  end

  @impl Galerie.UseCase
  def after_run(%{album: album}, _options) do
    Galerie.PubSub.broadcast({Galerie.Accounts.User, album.user_id}, {:album_created, album})
  end

  @impl Galerie.UseCase
  def return(%{album: album}, _options), do: album
end
