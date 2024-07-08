defmodule GalerieWeb.Library.Controller do
  use Phoenix.Controller, namespace: GalerieWeb
  alias Galerie.Directory

  action_fallback(Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  # TODO: The code below isn't safe, temporary solution to make it work
  def get(conn, %{"image" => image} = params) do
    file_location =
      params
      |> Map.get("type")
      |> file_path(image)

    if File.exists?(file_location) do
      send_download(conn, {:file, file_location})
    else
      conn
      |> put_status(404)
      |> halt()
    end
  end

  defp file_path("thumb", image) do
    Directory.thumbnail(image)
  end

  defp file_path("tiff", image) do
    Directory.raw_converted(image)
  end

  defp file_path(_, image) do
    image
  end
end
