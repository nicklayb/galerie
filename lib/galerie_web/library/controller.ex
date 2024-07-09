defmodule GalerieWeb.Library.Controller do
  use Phoenix.Controller, namespace: GalerieWeb
  alias Galerie.Library

  action_fallback(GalerieWeb.Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  def get(conn, %{"id" => picture_id} = params) do
    with {:ok, picture_id} <- Galerie.Ecto.check_uuid(picture_id),
         {:ok, type} <- type_param(params),
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

  def download(conn, %{"pictures" => picture_ids}) do
    pictures = Library.get_all_pictures(picture_ids)

    with {:ok, binary} <- Galerie.Downloader.download(pictures) do
      send_download(conn, {:binary, binary}, filename: "download.zip")
    end
  end
end
