defmodule GalerieWeb.Library.Controller do
  use Phoenix.Controller, namespace: GalerieWeb
  alias Galerie.Pictures

  action_fallback(GalerieWeb.Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  @six_months_in_seconds 15_552_000
  @cache_max_age @six_months_in_seconds
  def get(conn, %{"id" => picture_id} = params) do
    with {:ok, picture_id} <- Galerie.Ecto.check_uuid(picture_id),
         {:ok, type} <- type_param(params),
         {:ok, path} <- Pictures.get_picture_path(picture_id, type),
         {:ok, %File.Stat{mtime: mtime}} <- File.stat(path) do
      etag = build_etag(picture_id, mtime)

      conn
      |> put_resp_header("cache-control", "private; max-age: #{@cache_max_age}")
      |> put_resp_header("etag", etag)
      |> send_download({:file, path})
    end
  end

  defp build_etag(picture_id, mtime) do
    modified_time =
      mtime
      |> Tuple.to_list()
      |> Enum.flat_map(&Tuple.to_list/1)
      |> Enum.map_join(&to_string/1)

    "#{picture_id}.#{modified_time}"
  end

  defp type_param(params) do
    case Map.get(params, "type", "jpeg") do
      "jpeg" -> {:ok, :jpeg}
      "thumb" -> {:ok, :thumb}
      "original" -> {:ok, :original}
      invalid -> {:error, {:invalid, invalid}}
    end
  end

  def download(conn, %{"pictures" => picture_ids} = params) do
    pictures = Pictures.get_all_pictures(picture_ids)

    with {:ok, type} <- download_type_param(params),
         {:ok, binary} <- Galerie.Downloader.download(pictures, type) do
      send_download(conn, {:binary, binary}, filename: "download.zip")
    end
  end

  def download_type_param(params) do
    case Map.get(params, "type", "original") do
      "original" -> {:ok, :original}
      "jpeg" -> {:ok, :jpeg}
      invalid -> {:error, {:invalid, invalid}}
    end
  end
end
