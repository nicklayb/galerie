defmodule Nectarine.ActionHandlers.PubSub do
  @behaviour Gearbox.ActionHandler

  @impl Gearbox.ActionHandler
  def handle(_, _, _), do: :skip

  @impl Gearbox.ActionHandler
  def after_transaction(_, _, _), do: :skip
end
