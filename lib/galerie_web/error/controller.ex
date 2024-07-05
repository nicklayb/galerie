defmodule GalerieWeb.Error.Controller do
  use Phoenix.Controller, namespace: GalerieWeb

  plug(:put_view, GalerieWeb.Error.View)
end
