defmodule GalerieWeb.Settings.AccessLinks.Index do
  use GalerieWeb, {:live_view, layout: :settings}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Access Links"))

    {:ok, socket}
  end
end
