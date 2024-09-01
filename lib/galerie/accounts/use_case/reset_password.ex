defmodule Galerie.Accounts.UseCase.ResetPassword do
  @moduledoc """
  Use case to request a user reset password change. The user
  receives an email and can then use the reset password form
  to set a new password
  """
  use Galerie.UseCase

  alias Galerie.Accounts.User

  @impl Galerie.UseCase
  def run(multi, %User{} = user, _options) do
    Ecto.Multi.update(multi, :user, User.reset_password_changeset(user))
  end

  @impl Galerie.UseCase
  def after_run(%{user: user}, _options) do
    Galerie.Mailer.deliver_async(fn ->
      Galerie.Mailer.reset_password(user)
    end)
  end

  @impl Galerie.UseCase
  def return(%{user: user}, _options), do: user
end
