defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  alias Galerie.Library
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.FloatingPills
  alias GalerieWeb.Components.Picture
  alias GalerieWeb.Components.Ui

  import GalerieWeb.Gettext

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:updating, true)
      |> assign(:new_pictures, [])
      |> assign(:filter_selected, false)
      |> assign(:context_menu, false)
      |> assign(:last_index, 0)
      |> assign(:selected_pictures, MapSet.new())
      |> close_picture()
      |> start_async(:load_pictures, fn -> load_pictures(%{}) end)

    Galerie.PubSub.subscribe(Galerie.Picture)

    {:ok, socket}
  end

  def handle_async(:load_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign_pictures(page)
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

  def handle_event("filter-selected", _, socket) do
    socket = update(socket, :filter_selected, &(not &1))

    {:noreply, socket}
  end

  def handle_event(
        "picture-click",
        %{"shift_key" => true, "index" => index},
        socket
      ) do
    socket = toggle_between_index(socket, String.to_integer(index))
    {:noreply, socket}
  end

  def handle_event(
        "picture-click",
        %{"ctrl_key" => true, "index" => index, "picture_id" => picture_id},
        socket
      ) do
    socket =
      if picture_selected?(socket, picture_id) do
        deselect_picture(socket, picture_id, index)
      else
        select_picture(socket, picture_id, index)
      end

    {:noreply, socket}
  end

  def handle_event(
        "picture-click",
        %{"index" => index, "picture_id" => picture_id},
        %{assigns: %{pictures: %Page{results: pictures}}} = socket
      ) do
    socket =
      case Enum.find(pictures, &(&1.id == picture_id)) do
        %Galerie.Picture{} = picture ->
          view_picture(socket, picture, index)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("select-picture", %{"index" => index, "shift_key" => true}, socket) do
    socket = toggle_between_index(socket, String.to_integer(index))
    {:noreply, socket}
  end

  def handle_event("select-picture", %{"index" => index, "picture_id" => picture_id}, socket) do
    socket = select_picture(socket, picture_id, index)
    {:noreply, socket}
  end

  def handle_event("deselect-picture", %{"index" => index, "picture_id" => picture_id}, socket) do
    socket = deselect_picture(socket, picture_id, index)
    {:noreply, socket}
  end

  def handle_event("deselect-all", _, socket) do
    socket = assign(socket, :selected_pictures, MapSet.new())
    {:noreply, socket}
  end

  def handle_event(
        "viewer:keyup",
        %{"key" => "ArrowLeft"},
        %{assigns: %{highlighted_index: highlighted_index, pictures: %Page{results: pictures}}} =
          socket
      ) do
    socket =
      if highlighted_index > 0 do
        new_index = highlighted_index - 1

        picture = Enum.at(pictures, new_index)

        view_picture(socket, picture, new_index)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event(
        "viewer:keyup",
        %{"key" => "ArrowRight"},
        %{assigns: %{highlighted_index: highlighted_index, pictures: %Page{results: pictures}}} =
          socket
      ) do
    total_pictures = length(pictures)

    new_index =
      if highlighted_index >= total_pictures - 1 do
        0
      else
        highlighted_index + 1
      end

    picture = Enum.at(pictures, new_index)

    socket = view_picture(socket, picture, new_index)

    {:noreply, socket}
  end

  def handle_event(
        "viewer:keyup",
        %{"key" => "c"},
        %{assigns: %{highlighted_index: index, highlighted_picture: picture}} =
          socket
      ) do
    socket =
      if picture_selected?(socket, picture.id) do
        deselect_picture(socket, picture.id, index)
      else
        select_picture(socket, picture.id, index)
      end

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"key" => "Escape"}, socket) do
    socket = close_picture(socket)

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", _, socket) do
    {:noreply, socket}
  end

  def handle_event("viewer:close", _, socket) do
    socket = close_picture(socket)
    {:noreply, socket}
  end

  def handle_event("open-context-menu", _, socket) do
    socket = update(socket, :context_menu, &(not &1))
    {:noreply, socket}
  end

  def handle_event("reprocess", _, %{assigns: %{selected_pictures: selected_pictures}} = socket) do
    Enum.each(selected_pictures, fn picture_id ->
      Galerie.Jobs.Processor.enqueue(picture_id)
      Galerie.Jobs.ThumbnailGenerator.enqueue(picture_id)
    end)

    socket = assign(socket, :context_menu, false)

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

  defp assign_pictures(socket, pictures) do
    assign(socket, :pictures, Page.map_results(pictures, &Galerie.Picture.put_index/1))
  end

  defp select_picture(socket, picture_id, index) when is_binary(index),
    do: select_picture(socket, picture_id, String.to_integer(index))

  defp select_picture(socket, picture_id, index) do
    socket
    |> update(:selected_pictures, &MapSet.put(&1, picture_id))
    |> assign(:last_index, index)
  end

  defp deselect_picture(socket, picture_id, index) when is_binary(index),
    do: deselect_picture(socket, picture_id, String.to_integer(index))

  defp deselect_picture(socket, picture_id, index) do
    socket
    |> update(:selected_pictures, &MapSet.delete(&1, picture_id))
    |> then(fn socket ->
      if Enum.any?(socket.assigns.selected_pictures) do
        socket
      else
        assign(socket, :filter_selected, false)
      end
    end)
    |> assign(:last_index, index)
  end

  defp picture_selected?(%{assigns: %{selected_pictures: selected_pictures}}, picture_id) do
    MapSet.member?(selected_pictures, picture_id)
  end

  defp toggle_between_index(
         %{assigns: %{last_index: last_index, pictures: %Page{results: pictures}}} = socket,
         new_last_index
       ) do
    last_index = last_index + 1
    bottom_index = min(last_index, new_last_index)
    top_index = max(last_index, new_last_index)
    range = bottom_index..top_index
    new_pictures = Enum.slice(pictures, range)

    socket
    |> update(:selected_pictures, fn selected_pictures ->
      Enum.reduce(new_pictures, selected_pictures, &MapSet.Extra.toggle(&2, &1.id))
    end)
    |> assign(:last_index, new_last_index)
  end

  defp view_picture(socket, picture, index) when is_binary(index),
    do: view_picture(socket, picture, String.to_integer(index))

  defp view_picture(socket, picture, index) do
    socket
    |> assign(:highlighted_picture, picture)
    |> assign(:highlighted_index, index)
  end

  defp close_picture(socket), do: view_picture(socket, nil, nil)
end
