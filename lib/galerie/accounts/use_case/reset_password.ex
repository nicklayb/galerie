defmodule Galerie.Accounts.UseCase.ResetPassword do
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
