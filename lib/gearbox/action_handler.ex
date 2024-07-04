defmodule Gearbox.ActionHandler do
  @callback handle(
              Gearbox.Application.accumulator(),
              Gearbox.Application.action(),
              Gearbox.Application.metadata()
            ) :: Ecto.Multi.t() | :skip
  @callback after_transaction(Gearbox.Application.action(), any(), Gearbox.Application.metadata()) ::
              :ok | {:error, any()} | :skip
end
