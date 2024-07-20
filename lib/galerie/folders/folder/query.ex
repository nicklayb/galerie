defmodule Galerie.Folders.Folder.Query do
  require Ecto.Query

  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder

  def from, do: Ecto.Query.from(Folder, as: :folder)

  def by_user(query \\ from(), user)

  def by_user(query, %User{id: user_id, is_admin: true}) do
    Ecto.Query.where(
      query,
      [folder: folder],
      folder.user_id == ^user_id or is_nil(folder.user_id)
    )
  end

  def by_user(query, %User{id: user_id}) do
    Ecto.Query.where(query, [folder: folder], folder.user_id == ^user_id)
  end
end
