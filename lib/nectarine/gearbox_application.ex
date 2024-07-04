defmodule Nectarine.GearboxApplication do
  @behaviour Gearbox.Application

  alias Nectarine.ActionHandlers

  @application Nectarine.GearboxApplication

  def dispatch(namespace, action, user_id, metadata \\ []) do
    metadata =
      Keyword.update(metadata, :context, %{user_id: user_id}, &Map.put(&1, :user_id, user_id))

    Gearbox.Application.dispatch(@application, {namespace, action}, metadata)
  end

  @impl Gearbox.Application
  def middlewares(_), do: [Nectarine.Middleware.Policy]

  @impl Gearbox.Application
  def repo(_), do: Nectarine.Repo

  @impl Gearbox.Application
  def route(Nectarine.User, _), do: ActionHandlers.Account

  @impl Gearbox.Application
  def event_handlers(_, _), do: [ActionHandlers.PubSub, ActionHandlers.Mailer]
end
