defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  alias Galerie.Library
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.Picture

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> start_async(:load_pictures, fn -> load_pictures(socket) end)

    Galerie.PubSub.subscribe(Galerie.Picture)

    {:ok, socket}
  end

  def handle_async(:load_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign(:pictures, page)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  defp load_pictures(%{assigns: %{pictures: %Page{} = previous_page}}) do
    new_page = Repo.next(previous_page)
    Page.merge(previous_page, new_page)
  end

  defp load_pictures(_) do
    Library.list_pictures([])
  end
end
