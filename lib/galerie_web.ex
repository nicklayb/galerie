defmodule GalerieWeb do
  def live_view do
    live_view([])
  end

  def live_view(options) do
    layout = Keyword.get(options, :layout, :app)

    quote do
      use Phoenix.LiveView,
        container: {:div, class: "h-full"},
        layout: {GalerieWeb.Components.Layouts, unquote(layout)}

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

  defmacro __using__({type, options}) do
    apply(__MODULE__, type, [options])
  end

  defmacro __using__(type) do
    apply(__MODULE__, type, [])
  end
end
