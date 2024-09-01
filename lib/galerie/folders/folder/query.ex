defmodule Galerie.Folders.Folder.Query do
  @moduledoc """
  Module responsible for query building the Folder schema.
  """
  require Ecto.Query

  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder

  @doc """
  Base query with named binding.
  """
  @spec from() :: Ecto.Query.t()
  def from, do: Ecto.Query.from(Folder, as: :folder)

  @doc """
  Filters folder for a given user. For non-admin users, these *won't*
  included local folders.
  """
  @spec by_user(Ecto.Queryable.t(), User.t()) :: Ecto.Query.t()
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
