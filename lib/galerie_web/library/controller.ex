defmodule GalerieWeb.Library.Controller do
  use Phoenix.Controller, namespace: GalerieWeb
  alias Galerie.Library

  action_fallback(Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  def get(conn, %{"id" => picture_id} = params) do
    with {:ok, type} <- type_param(params),
         {:ok, path} <- Library.get_picture_path(picture_id, type) do
      send_download(conn, {:file, path})
    end
  end

  defp type_param(params) do
    case Map.get(params, "type", "jpeg") do
      "jpeg" -> {:ok, :jpeg}
      "thumb" -> {:ok, :thumb}
      "original" -> {:ok, :original}
      invalid -> {:error, {:invalid, invalid}}
    end
  end
end
