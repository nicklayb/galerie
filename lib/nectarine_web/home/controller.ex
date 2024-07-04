defmodule NectarineWeb.Home.Controller do
  use Phoenix.Controller, namespace: NectarineWeb

  action_fallback(Error.Controller)
  plug(:put_view, NectarineWeb.Home.View)

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
