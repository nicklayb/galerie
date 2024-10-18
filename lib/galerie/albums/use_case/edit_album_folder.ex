defmodule Galerie.Albums.UseCase.EditAlbumFolder do
  @moduledoc """
  Use case to edit an album folder. Since albums belongs to a given user,
  the user needs to provided as part of the options.
  """
  use Galerie.UseCase
  alias Galerie.Albums.AlbumFolder

  @impl Galerie.UseCase
  def validate(params, options) do
    album_folder_id = Map.Extra.get(params, :album_folder_id)

    with {:ok, %AlbumFolder{} = album_folder} <-
           Galerie.Albums.get_album_folder_belonging_to_user(
             album_folder_id,
             Keyword.get(options, :user)
           ) do
      {:ok, {params, album_folder}}
    end
  end

  @impl Galerie.UseCase
  def run(multi, {params, %AlbumFolder{} = album_folder}, _options) do
    Ecto.Multi.update(
      multi,
      :album_folder,
      AlbumFolder.update_changeset(album_folder, params)
    )
  end

  @impl Galerie.UseCase
  def after_run(%{album_folder: album_folder}, _options) do
    Galerie.PubSub.broadcast(
      {Galerie.Accounts.User, album_folder.user_id},
      {:album_folder_updated, album_folder}
    )
  end

  @impl Galerie.UseCase
  def return(%{album_folder: album_folder}, _options), do: album_folder
end
