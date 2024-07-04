defmodule NectarineWeb.Error.Controller do
  use Phoenix.Controller, namespace: NectarineWeb

  plug(:put_view, NectarineWeb.Error.View)
end
