defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  alias Galerie.Jobs.Importer
  alias Galerie.Pictures
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.Dropzone
  alias GalerieWeb.Components.FloatingPills
  alias GalerieWeb.Components.Picture
  alias GalerieWeb.Components.Ui

  import GalerieWeb.Gettext

  @defaults %{
    updating: true,
    new_pictures: [],
    filter_selected: false,
    context_menu: false,
    last_index: 0,
    end_index: 0,
    has_next_page: false,
    has_previous_page: false,
    selected_pictures: MapSet.new()
  }

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(@defaults)
      |> setup_upload()
      |> close_picture()
      |> start_async(:load_pictures, fn -> load_pictures(%{}) end)

    Galerie.PubSub.subscribe(Galerie.Pictures.Picture)

    {:ok, socket}
  end

  @max_entries 10
  @max_file_size Galerie.FileSize.parse("50mb")
  defp setup_upload(socket) do
    socket
    |> assign(:uploading_entries, %{})
    |> allow_upload(
      :upload_pictures,
      accept: [".jpg", "application/octet-stream"],
      max_entries: @max_entries,
      max_file_size: @max_file_size,
      progress: &handle_progress/3,
      auto_upload: true
    )
  end

  @remove_after_timeout :timer.seconds(3)
  defp handle_progress(:upload_pictures, entry, socket) do
    socket = Phoenix.Component.update(socket, :uploading_entries, &Map.put(&1, entry.uuid, entry))

    if entry.done? do
      Phoenix.LiveView.consume_uploaded_entry(socket, entry, fn %{path: path} ->
        entry_consumed(socket, entry, path)
      end)

      Process.send_after(self(), {:remove_uploading_entry, entry.uuid}, @remove_after_timeout)
    end

    {:noreply, socket}
  end

  defp entry_consumed(socket, entry, path) do
    if Pictures.valid_file_type?(path) do
      destination =
        Galerie.Directory.upload_output(socket.assigns.current_user, entry.client_name)

      path
      |> copy_file(destination)
      |> Result.tap(fn destination ->
        Importer.enqueue(destination, socket.assigns.current_user.folder)
      end)
    else
      {:ok, nil}
    end
  end

  defp copy_file(source, destination) do
    with :ok <- File.cp(source, destination) do
      {:ok, destination}
    end
  end

  def handle_async(:load_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign_pictures(page)
      |> assign(:updating, false)
      |> assign(:scroll_disabled, false)

    {:noreply, socket}
  end

  def handle_async(:load_next_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign_pictures(page)
      |> assign(:updating, false)
      |> assign(:scroll_disabled, false)
      |> then(fn %{
                   assigns: %{
                     pictures: %Page{results: pictures},
                     highlighted_index: highlighted_index
                   }
                 } = socket ->
        new_index = highlighted_index + 1
        picture = Enum.at(pictures, new_index)

        view_picture(socket, picture, new_index)
      end)

    {:noreply, socket}
  end

  defp load_pictures(%{pictures: %Page{} = previous_page}) do
    new_page = Repo.next(previous_page)

    Page.merge(previous_page, new_page)
  end

  defp load_pictures(_) do
    Pictures.list_pictures([])
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
        %Galerie.Pictures.PictureItem{} = picture ->
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
    socket =
      socket
      |> assign(:selected_pictures, MapSet.new())
      |> update_context_menu_visible()

    {:noreply, socket}
  end

  def handle_event(
        "viewer:keyup",
        %{"key" => "ArrowLeft"},
        %{
          assigns: %{
            highlighted_index: highlighted_index,
            has_previous_page: has_previous_page?,
            pictures: %Page{results: pictures}
          }
        } =
          socket
      ) do
    socket =
      if has_previous_page? do
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
        %{
          assigns: %{
            highlighted_index: highlighted_index,
            has_next_page: has_next_page?,
            end_index: end_index,
            pictures: %Page{results: pictures}
          }
        } =
          socket
      ) do
    socket =
      cond do
        has_next_page? and highlighted_index == end_index ->
          load_next_page(socket)

        has_next_page? ->
          new_index = highlighted_index + 1
          picture = Enum.at(pictures, new_index)

          view_picture(socket, picture, new_index)

        true ->
          socket
      end

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
    end)

    socket = assign(socket, :context_menu, false)

    {:noreply, socket}
  end

  def handle_event("validate_file", %{"_target" => _}, socket) do
    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :thumbnail_generated,
          params: %Galerie.Pictures.Picture{} = picture
        },
        socket
      ) do
    socket =
      update(socket, :new_pictures, &[picture.id | &1])

    {:noreply, socket}
  end

  def handle_info({:remove_uploading_entry, uuid}, socket) do
    socket =
      Phoenix.Component.update(socket, :uploading_entries, fn entries ->
        Map.delete(entries, uuid)
      end)

    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{}, socket) do
    {:noreply, socket}
  end

  defp assign_pictures(socket, pictures) do
    pictures = Page.map_results(pictures, &Galerie.Pictures.PictureItem.put_index/1)
    end_index = length(pictures.results) - 1

    socket
    |> assign(:pictures, pictures)
    |> assign(:end_index, end_index)
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
    |> update_context_menu_visible()
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
    |> then(fn socket ->
      has_previous_page = not first_index?(socket)
      has_next_page = not last_index?(socket)

      socket
      |> assign(:has_next_page, has_next_page)
      |> assign(:has_previous_page, has_previous_page)
    end)
  end

  defp close_picture(socket), do: view_picture(socket, nil, nil)

  defp update_context_menu_visible(
         %{assigns: %{context_menu: true, selected_pictures: selected_pictures}} = socket
       ) do
    if Enum.empty?(selected_pictures) do
      assign(socket, :context_menu, false)
    else
      socket
    end
  end

  defp update_context_menu_visible(socket), do: socket

  defp first_index?(%{assigns: %{highlighted_index: index}}), do: index == 0

  defp last_index?(%{assigns: %{pictures: %Page{has_next_page: true}}}), do: false

  defp last_index?(%{assigns: %{highlighted_index: index, end_index: end_index}}) do
    index == end_index
  end

  defp load_next_page(
         %{
           assigns:
             %{
               highlighted_index: index,
               end_index: index,
               pictures: %Page{has_next_page: true}
             } = assigns
         } = socket
       ) do
    start_async(socket, :load_next_pictures, fn -> load_next_page(assigns) end)
  end

  defp load_next_page(socket) do
    socket
  end
end
