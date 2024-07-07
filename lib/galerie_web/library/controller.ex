defmodule GalerieWeb.Library.Controller do
  alias Galerie.Folder
  use Phoenix.Controller, namespace: GalerieWeb

  action_fallback(Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  # TODO: The code below isn't safe, temporary solution to make it work
  def get(conn, %{"image" => image}) do
    thumbnail_location = Folder.thumbnail(image)

    if File.exists?(thumbnail_location) do
      send_download(conn, {:file, thumbnail_location})
    else
      conn
      |> put_status(404)
      |> halt()
    end
  end
end
