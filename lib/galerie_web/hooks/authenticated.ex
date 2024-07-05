defmodule GalerieWeb.Hooks.Authenticated do
  alias GalerieWeb.Authentication
  use GalerieWeb.Components.Routes

  def on_mount(:default, _params, session, socket) do
    socket
    |> Phoenix.Component.assign_new(:current_user, fn -> nil end)
    |> Phoenix.Component.assign_new(:live_session_id, fn ->
      Map.get(session, "live_session_id")
    end)
    |> authenticate(session)
  end

  defp authenticate(socket, session) do
    case Authentication.authenticate(socket, session) do
      {:ok, socket} ->
        {:cont, socket}

      _ ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p(/logout))}
    end
  end
end
