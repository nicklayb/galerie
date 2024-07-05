defmodule GalerieWeb.Components.Routes do
  defmacro __using__(_) do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: GalerieWeb.Endpoint,
        router: GalerieWeb.Router,
        statics: GalerieWeb.Components.Routes.static_paths()
    end
  end

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
end
