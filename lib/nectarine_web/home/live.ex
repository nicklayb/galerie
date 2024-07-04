defmodule NectarineWeb.Home.Live do
  use NectarineWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
