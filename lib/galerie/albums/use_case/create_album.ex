defmodule Galerie.Albums.UseCase.CreateAlbum do
  @moduledoc """
  Use case to create an album. Since albums belongs to a given user,
  the user needs to provided as part of the params.
  """
  use Galerie.UseCase
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album

  @impl Box.UseCase
  def validate(params, options) do
    with {:ok, %User{id: user_id}} <- Galerie.UseCase.can?(options, :create_album) do
      {:ok, Box.Map.put(params, :user_id, user_id)}
    end
  end

  @impl Box.UseCase
  def run(multi, params, _options) do
    Ecto.Multi.insert(multi, :album, Album.changeset(params))
  end

  @impl Box.UseCase
  def after_run(%{album: album}, _options) do
    Galerie.PubSub.broadcast({Galerie.Accounts.User, album.user_id}, {:album_created, album})
  end

  @impl Box.UseCase
  def return(%{album: album}, _options), do: album
end
