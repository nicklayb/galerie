defmodule Galerie.Albums.UseCase.CreateAlbumFolder do
  @moduledoc """
  Use case to create an album folder. Since albums belongs to a given user,
  the user needs to provided as part of the params.
  """
  use Galerie.UseCase
  alias Galerie.Accounts.User
  alias Galerie.Albums.AlbumFolder

  @impl Galerie.UseCase
  def validate(params, options) do
    with {:ok, %User{id: user_id}} <- Galerie.UseCase.can?(options, :create_album) do
      {:ok, Map.Extra.put(params, :user_id, user_id)}
    end
  end

  @impl Galerie.UseCase
  def run(multi, params, _options) do
    Ecto.Multi.insert(multi, :album_folder, AlbumFolder.changeset(params))
  end

  @impl Galerie.UseCase
  def after_run(%{album_folder: album_folder}, _options) do
    Galerie.PubSub.broadcast(
      {Galerie.Accounts.User, album_folder.user_id},
      {:album_folder_created, album_folder}
    )
  end

  @impl Galerie.UseCase
  def return(%{album_folder: album_folder}, _options), do: album_folder
end
