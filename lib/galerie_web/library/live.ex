defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  alias Galerie.Library
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Picture
  alias GalerieWeb.Components.Ui

  import GalerieWeb.Gettext

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:updating, true)
      |> assign(:new_pictures, [])
      |> assign(:selected_pictures, MapSet.new())
      |> start_async(:load_pictures, fn -> load_pictures(%{}) end)

    Galerie.PubSub.subscribe(Galerie.Picture)

    {:ok, socket}
  end

  def handle_async(:load_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign(:pictures, page)
      |> assign(:updating, false)
      |> assign(:scroll_disabled, false)

    {:noreply, socket}
  end

  defp load_pictures(%{pictures: %Page{} = previous_page}) do
    new_page = Repo.next(previous_page)
    Page.merge(previous_page, new_page)
  end

  defp load_pictures(_) do
    Library.list_pictures([])
  end

  def handle_event("scrolled-bottom", _params, socket) do
    assigns = socket.assigns

    socket =
      socket
      |> assign(:scroll_disabled, true)
      |> start_async(:load_pictures, fn -> load_pictures(assigns) end)

    {:noreply, socket}
  end

  def handle_event("clear-new-pictures", _, socket) do
    socket = assign(socket, :new_pictures, [])
    {:noreply, socket}
  end

  def handle_event("deselect-picture", %{"picture_id" => picture_id}, socket) do
    socket = update(socket, :selected_pictures, &MapSet.delete(&1, picture_id))

    {:noreply, socket}
  end

  def handle_event("select-picture", %{"picture_id" => picture_id}, socket) do
    socket = update(socket, :selected_pictures, &MapSet.put(&1, picture_id))

    {:noreply, socket}
  end

  def handle_event("deselect-all", _, socket) do
    socket = assign(socket, :selected_pictures, MapSet.new())
    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :thumbnail_generated,
          params: %Galerie.Picture{} = picture
        },
        socket
      ) do
    socket =
      update(socket, :new_pictures, &[picture.id | &1])

    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{}, socket) do
    {:noreply, socket}
  end
end
