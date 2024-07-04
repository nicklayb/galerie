defmodule NectarineWeb.Hooks.UrlUpdated do
  alias Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(:current_uri, nil)
      |> Phoenix.Component.assign(:current_uri_params, %{})
      |> LiveView.attach_hook(:url_updated, :handle_params, &handle_params/3)

    {:cont, socket}
  end

  defp handle_params(params, uri, socket) do
    socket =
      socket
      |> Phoenix.Component.assign(:current_uri, URI.parse(uri))
      |> Phoenix.Component.assign(:current_uri_params, params)
      |> broadcast_session()

    {:cont, socket}
  end

  defp broadcast_session(%{assigns: %{live_session_id: session_id, current_uri: uri}} = socket) do
    Nectarine.PubSub.broadcast({:live_session, session_id}, {:url_updated, uri})
    socket
  end

  defp broadcast_session(socket), do: socket
end
