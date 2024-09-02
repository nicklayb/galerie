defmodule GalerieWeb do
  def live_view do
    quote do
      use Phoenix.LiveView, container: {:div, class: "h-full"}

      on_mount(GalerieWeb.Hooks.LiveSession)
      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      use GalerieWeb.Components.Routes

      import GalerieWeb.Gettext

      require Galerie.PubSub
      require Logger

      alias GalerieWeb.Html
      alias GalerieWeb.UseCase
    end
  end

  defmacro __using__(type) do
    apply(__MODULE__, type, [])
  end
end
