defmodule Nectarine.ActionHandlers.Account do
  @behaviour Gearbox.ActionHandler

  require Logger

  alias Nectarine.User

  @impl Gearbox.ActionHandler
  def handle(multi, {User, {:create, params}}, _) do
    Ecto.Multi.insert(multi, :user, User.changeset(params))
  end

  def handle(multi, {User, {:reset_password, %User{} = user}}, _) do
    Ecto.Multi.update(multi, :user, User.reset_password_changeset(user))
  end

  def handle(multi, {User, {:update_password, %User{} = user, params}}, _) do
    Ecto.Multi.update(multi, :user, User.update_password_changeset(user, params))
  end

  def handle(_, _, _), do: :skip

  @impl Gearbox.ActionHandler
  def after_transaction(_, _, _), do: :skip
end
