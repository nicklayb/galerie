defmodule NectarineWeb.Components.Routes do
  defmacro __using__(_) do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: NectarineWeb.Endpoint,
        router: NectarineWeb.Router,
        statics: NectarineWeb.Components.Routes.static_paths()
    end
  end

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
end
