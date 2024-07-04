defmodule NectarineWeb.Hooks.LiveSession do
  use NectarineWeb.Components.Routes

  def on_mount(:default, _params, _, socket) do
    socket =
      if Phoenix.LiveView.connected?(socket) do
        Nectarine.PubSub.subscribe({:live_session, socket.assigns.live_session_id})

        Phoenix.LiveView.attach_hook(
          socket,
          :session_redirect,
          :handle_info,
          fn
            %Nectarine.PubSub.Message{message: :redirect, params: path}, socket ->
              {:halt, Phoenix.LiveView.push_navigate(socket, to: path)}

            _, socket ->
              {:cont, socket}
          end
        )
      else
        socket
      end

    {:cont, socket}
  end

  def session(%Plug.Conn{assigns: %{session_id: session_id}}) do
    %{"live_session_id" => session_id}
  end
end
