defmodule GalerieWeb.Library.Controller do
  alias Galerie.Folder
  use Phoenix.Controller, namespace: GalerieWeb

  action_fallback(Error.Controller)
  plug(:put_view, GalerieWeb.Library.View)

  def get(conn, %{"image" => image}) do
    thumbnail_location = Folder.thumbnail_output(image)

    conn
    |> send_download({:file, thumbnail_location})
  end
end
