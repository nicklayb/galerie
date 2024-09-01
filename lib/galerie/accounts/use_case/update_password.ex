defmodule Galerie.Accounts.UseCase.UpdatePassword do
  @moduledoc """
  Use case to update a user's password.
  """
  use Galerie.UseCase

  alias Galerie.Accounts.User

  @impl Galerie.UseCase
  def run(multi, {%User{} = user, params}, _options) do
    Ecto.Multi.update(multi, :user, User.update_password_changeset(user, params))
  end

  @impl Galerie.UseCase
  def return(%{user: user}, _options), do: user
end
