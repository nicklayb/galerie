defmodule GalerieWeb.Library.Controller do
  use Phoenix.Controller, namespace: GalerieWeb

  action_fallback(Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
