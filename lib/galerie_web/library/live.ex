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
    pictures: nil,
    new_pictures: [],
    filter_selected: false,
    context_menu: false,
    highlighted_picture: nil,
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
      |> update_pictures(&SelectableList.highlight_next/1)

    {:noreply, socket}
  end

  defp load_pictures(%{pictures: %Page{} = previous_page}) do
    new_page = Repo.next(previous_page)

    Page.merge(previous_page, new_page, &SelectableList.append/2)
  end

  defp load_pictures(_) do
    Repo.Page.map_results(Pictures.list_pictures(), &SelectableList.new/1)
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
        %{"ctrl_key" => true, "index" => index},
        socket
      ) do
    socket =
      update_pictures(socket, &SelectableList.toggle_by_index(&1, String.to_integer(index)))

    {:noreply, socket}
  end

  def handle_event("picture-click", %{"index" => index}, socket) do
    socket = update_pictures(socket, &SelectableList.highlight(&1, String.to_integer(index)))

    {:noreply, socket}
  end

  def handle_event("select-picture", %{"index" => index, "shift_key" => true}, socket) do
    socket = toggle_between_index(socket, String.to_integer(index))
    {:noreply, socket}
  end

  def handle_event("select-picture", %{"index" => index}, socket) do
    socket =
      update_pictures(socket, &SelectableList.select_by_index(&1, String.to_integer(index)))

    {:noreply, socket}
  end

  def handle_event("deselect-picture", %{"index" => index}, socket) do
    socket =
      socket
      |> update_pictures(&SelectableList.deselect_by_index(&1, index))
      |> then(fn socket ->
        if SelectableList.any_selected?(socket.assigns.pictures) do
          socket
        else
          assign(socket, :filter_selected, false)
        end
      end)
      |> update_context_menu_visible()

    {:noreply, socket}
  end

  def handle_event("deselect-all", _, socket) do
    socket =
      socket
      |> assign(:selected_pictures, MapSet.new())
      |> update_context_menu_visible()

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"key" => "ArrowLeft"}, socket) do
    socket = update_pictures(socket, &SelectableList.highlight_previous/1)

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"key" => "ArrowRight"}, socket) do
    socket = load_next_page(socket)

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"key" => "c"}, socket) do
    socket =
      update_pictures(
        socket,
        &SelectableList.toggle_by_index(&1, socket.assigns.pictures.results.highlighted_index)
      )

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
    socket
    |> assign(:pictures, pictures)
    |> assign(:end_index, pictures.results.count - 1)
  end

  defp toggle_between_index(socket, new_last_index) do
    update_pictures(socket, &SelectableList.toggle_until(&1, new_last_index))
  end

  defp close_picture(socket) do
    update_pictures(socket, &SelectableList.unhighlight/1)
  end

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

  defp load_next_page(
         %{
           assigns:
             %{
               pictures: %Page{results: results, has_next_page: has_next_page}
             } = assigns
         } = socket
       ) do
    cond do
      not SelectableList.last_highlighted?(results) ->
        update_pictures(socket, &SelectableList.highlight_next/1)

      has_next_page and SelectableList.last_highlighted?(results) ->
        start_async(socket, :load_next_pictures, fn -> load_pictures(assigns) end)

      true ->
        socket
    end
  end

  defp update_pictures(socket, function) do
    update(socket, :pictures, fn page -> Page.map_results(page, function) end)
  end
end
