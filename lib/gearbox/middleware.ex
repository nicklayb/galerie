defmodule Gearbox.Middleware do
  @callback run(Gearbox.Application.action(), Gearbox.Application.context()) ::
              :continue
              | {:continue, Gearbox.Application.context()}
              | {:abort, term()}
end
