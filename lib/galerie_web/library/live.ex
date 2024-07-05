defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
