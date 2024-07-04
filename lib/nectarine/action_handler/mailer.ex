defmodule Nectarine.ActionHandlers.Mailer do
  @behaviour Gearbox.ActionHandler

  require Logger

  @impl Gearbox.ActionHandler
  def handle(_, _, _), do: :skip

  @impl Gearbox.ActionHandler
  def after_transaction(
        {Nectarine.User, {:create, _}},
        %{user: %Nectarine.User{} = user},
        _
      ) do
    Nectarine.Mailer.deliver_async(fn ->
      Nectarine.Mailer.welcome(user)
    end)
  end

  def after_transaction(
        {Nectarine.User, {:reset_password, _}},
        %{user: %Nectarine.User{} = user},
        _
      ) do
    Nectarine.Mailer.deliver_async(fn ->
      Nectarine.Mailer.reset_password(user)
    end)
  end

  def after_transaction(_, _, _), do: :skip
end
