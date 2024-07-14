defmodule Galerie.Albums do
  alias Galerie.Accounts.User
  alias Galerie.Albums.Album
  alias Galerie.Repo

  def create_album(%User{id: user_id}, params) do
    %Album{}
    |> Album.changeset(Map.Extra.put(params, :user_id, user_id))
    |> Repo.insert()
  end
end
