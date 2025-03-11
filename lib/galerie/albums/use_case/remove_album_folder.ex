defmodule Galerie.Albums.UseCase.RemoveAlbumFolder do
  @moduledoc """
  Use case to remove an album folder. Since albums belongs to a given user,
  the user needs to provided as part of the options.
  """
  use Galerie.UseCase
  alias Galerie.Albums.AlbumFolder

  @impl Box.UseCase
  def validate(album_id, options) do
    Galerie.Albums.get_album_folder_belonging_to_user(album_id, Keyword.get(options, :user))
  end

  @impl Box.UseCase
  def run(multi, %AlbumFolder{} = album_folder, _options) do
    Ecto.Multi.delete(multi, :album_folder, album_folder)
  end

  @impl Box.UseCase
  def after_run(%{album_folder: album_folder}, _options) do
    Galerie.PubSub.broadcast(
      {Galerie.Accounts.User, album_folder.user_id},
      {:album_folder_deleted, album_folder}
    )
  end

  @impl Box.UseCase
  def return(%{album_folder: album_folder}, _options), do: album_folder
end
