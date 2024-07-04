defmodule GalerieWeb do
  def live_view do
    quote do
      use Phoenix.LiveView, container: {:div, class: "h-full"}
      use GalerieWeb.Components.Routes

      on_mount(GalerieWeb.Hooks.LiveSession)
    end
  end

  defmacro __using__(type) do
    apply(__MODULE__, type, [])
  end
end
