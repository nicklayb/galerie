defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  require Logger

  alias Galerie.Accounts.User
  alias Galerie.Albums
  alias Galerie.Albums.Album
  alias Galerie.Folders
  alias Galerie.Jobs.Importer
  alias Galerie.Pictures
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.Dropzone
  alias GalerieWeb.Components.FloatingPills
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Components.Picture
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  import GalerieWeb.Gettext

  @defaults %{
    updating: true,
    pictures: nil,
    new_pictures: [],
    filter_selected: false,
    modal: nil,
    jobs: %{},
    folders: [],
    albums: SelectableList.new([])
  }

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(@defaults)
      |> setup_upload()
      |> start_async(:load_folders, fn -> Folders.get_user_folders(current_user) end)
      |> start_async(:load_jobs, fn -> {true, Galerie.ObanRepo.pending_jobs()} end)
      |> start_async(:load_albums, fn -> load_albums(current_user) end)

    Galerie.PubSub.subscribe(current_user)

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

  def handle_async(:load_folders, {:ok, folders}, socket) do
    socket =
      socket
      |> assign(:folders, folders)
      |> then(fn socket ->
        assigns = socket.assigns
        start_async(socket, :load_pictures, fn -> load_pictures(assigns) end)
      end)

    Enum.each(folders, &Galerie.PubSub.subscribe/1)

    {:noreply, socket}
  end

  def handle_async(:load_jobs, {:ok, {on_mount?, jobs}}, socket) do
    jobs =
      Enum.reduce(jobs, %{}, fn {key, count}, acc ->
        Map.put(acc, String.to_existing_atom(key), count)
      end)

    if on_mount? do
      Galerie.PubSub.subscribe("oban:job")
    end

    {:noreply, assign(socket, :jobs, jobs)}
  end

  def handle_async(:load_albums, {:ok, albums}, %{assigns: %{albums: old_albums}} = socket) do
    socket = assign(socket, :albums, albums)

    Enum.each(old_albums, fn {_, album} -> Galerie.PubSub.unsubscribe(album) end)

    Enum.each(albums, fn {_, album} -> Galerie.PubSub.subscribe(album) end)

    {:noreply, socket}
  end

  def handle_async(:load_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign_pictures(page)
      |> assign(:updating, false)
      |> assign(:scroll_disabled, false)
      |> update_picture_index()

    {:noreply, socket}
  end

  def handle_async(:load_next_pictures, {:ok, page}, socket) do
    socket =
      socket
      |> assign_pictures(page)
      |> assign(:updating, false)
      |> assign(:scroll_disabled, false)
      |> update_pictures(&SelectableList.highlight_next/1)
      |> update_picture_index()

    {:noreply, socket}
  end

  defp next_page(%{pictures: %Page{} = previous_page}) do
    new_page = Repo.next(previous_page)

    Page.merge(previous_page, new_page, &SelectableList.append/2)
  end

  defp load_pictures(assigns) do
    query_options = pictures_filter(assigns)

    assigns.folders
    |> Enum.Extra.field(:id)
    |> Pictures.list_pictures(query_options)
    |> Repo.Page.map_results(&SelectableList.new/1)
  end

  defp load_albums(%User{} = current_user) do
    current_user
    |> Albums.get_user_albums()
    |> SelectableList.new()
  end

  defp pictures_filter(assigns) do
    album_ids =
      assigns
      |> Map.get_lazy(:albums, fn -> SelectableList.new([]) end)
      |> SelectableList.selected_items(fn {_, item} -> item.id end)

    [
      album_ids: album_ids
    ]
  end

  def handle_event("create-album", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.CreateAlbum, current_user: socket.assigns.current_user}
      )

    {:noreply, socket}
  end

  def handle_event("scrolled-bottom", _params, socket) do
    assigns = socket.assigns

    socket =
      socket
      |> assign(:scroll_disabled, true)
      |> start_async(:load_pictures, fn -> next_page(assigns) end)

    {:noreply, socket}
  end

  def handle_event("clear-new-pictures", _, socket) do
    socket = assign(socket, :new_pictures, [])
    {:noreply, socket}
  end

  def handle_event("selection_bar:filter-selected", _, socket) do
    socket = update(socket, :filter_selected, &(not &1))

    {:noreply, socket}
  end

  def handle_event("filter-album", %{"ctrl_key" => true, "index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      socket
      |> update(:albums, fn albums ->
        SelectableList.toggle_by_index(albums, index)
      end)
      |> reload_pictures()

    {:noreply, socket}
  end

  def handle_event("filter-album", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      socket
      |> update(:albums, fn albums ->
        if SelectableList.multiple_selected?(albums) do
          SelectableList.toggle_by_index(albums, index)
        else
          SelectableList.toggle_only(albums, index)
        end
      end)
      |> reload_pictures()

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
    socket = update_pictures(socket, &SelectableList.deselect_by_index(&1, index))

    {:noreply, socket}
  end

  def handle_event("selection_bar:clear", _, socket) do
    socket = update_pictures(socket, &SelectableList.clear_selected/1)

    {:noreply, socket}
  end

  def handle_event("selection_bar:download", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.Download,
         [selectable_list: socket.assigns.pictures.results]}
      )

    {:noreply, socket}
  end

  def handle_event("selection_bar:add-to-album", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.AddToAlbum,
         [
           selectable_list: socket.assigns.pictures.results,
           albums: SelectableList.new(socket.assigns.albums)
         ]}
      )

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"_target" => _}, socket) do
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

  def handle_event("viewer:keyup", %{"key" => "c"} = params, socket) do
    params |> IO.inspect()

    socket =
      if SelectableList.highlighted?(socket.assigns.pictures.results) do
        update_pictures(
          socket,
          &SelectableList.toggle_by_index(&1, socket.assigns.pictures.results.highlighted_index)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", %{"key" => "Escape"}, %{assigns: %{modal: modal}} = socket)
      when not is_nil(modal) do
    socket = assign(socket, :modal, nil)

    {:noreply, socket}
  end

  def handle_event(
        "viewer:keyup",
        %{"key" => "Escape"},
        %{assigns: %{pictures: %{results: %SelectableList{highlighted_index: index}}}} = socket
      )
      when not is_nil(index) do
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

  def handle_event("modal:close", _, socket) do
    socket = assign(socket, :modal, nil)
    {:noreply, socket}
  end

  def handle_event("validate_file", %{"_target" => _}, socket) do
    {:noreply, socket}
  end

  def handle_info(:sync_albums, socket) do
    current_user = socket.assigns.current_user
    socket = start_async(socket, :load_albums, fn -> load_albums(current_user) end)
    {:noreply, socket}
  end

  def handle_info(:close_modal, socket) do
    socket = assign(socket, :modal, nil)
    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :processed,
          params: %Galerie.Pictures.Picture{} = picture
        } = message,
        socket
      ) do
    if highlighted?(socket, picture) do
      send_update(Picture.Viewer, id: "viewer", message: message)
    end

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

  def handle_info(%Galerie.PubSub.Message{message: :job_stop}, socket) do
    socket = update_jobs(socket, %{executing: -1})
    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{message: :job_insert}, socket) do
    socket = update_jobs(socket, %{available: 1})
    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{message: :job_exception}, socket) do
    socket = update_jobs(socket, %{retryable: 1, executing: -1})
    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{message: :job_start}, socket) do
    socket = update_jobs(socket, %{executing: 1, available: -1})
    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :removed_from_album,
          params: %{album: album, group: group}
        } = message,
        socket
      ) do
    socket = update(socket, :albums, &put_album(&1, album))

    if highlighted?(socket, group) do
      send_update(self(), Picture.Viewer, id: "pictureViewer", message: message)
    end

    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :album_created
        },
        socket
      ) do
    current_user = socket.assigns.current_user
    socket = start_async(socket, :load_albums, fn -> load_albums(current_user) end)

    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{message: message}, socket) do
    Logger.warning("[#{inspect(__MODULE__)}] [handle_info] [unhandled_pub_sub] #{message}")
    {:noreply, socket}
  end

  defp put_album(%SelectableList{} = albums, %Album{id: album_id} = album) do
    SelectableList.update(albums, fn current_album ->
      {current_album.id == album_id, album}
    end)
  end

  defp update_jobs(socket, updates) do
    update(socket, :jobs, fn current_jobs ->
      Enum.reduce(updates, current_jobs, fn {key, increment}, acc ->
        Map.update(acc, key, increment, &(&1 + increment))
      end)
    end)
  end

  defp assign_pictures(socket, pictures) do
    assign(socket, :pictures, pictures)
  end

  defp toggle_between_index(socket, new_last_index) do
    update_pictures(socket, &SelectableList.toggle_until(&1, new_last_index))
  end

  defp close_picture(socket) do
    update_pictures(socket, &SelectableList.unhighlight/1)
  end

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
    socket
    |> update(:pictures, fn page -> Page.map_results(page, function) end)
    |> clear_filter_selected_if_none_selected()
  end

  defp update_picture_index(%{assigns: %{pictures: %{results: results}}} = socket) do
    index =
      Enum.reduce(results, %{}, fn {index, %{group_id: group_id}}, acc ->
        Map.put(acc, group_id, index)
      end)

    assign(socket, :picture_index, index)
  end

  defp clear_filter_selected_if_none_selected(%{assigns: %{filter_selected: true}} = socket) do
    if SelectableList.any_selected?(socket.assigns.pictures.results) do
      socket
    else
      assign(socket, :filter_selected, false)
    end
  end

  defp clear_filter_selected_if_none_selected(socket), do: socket

  defp reload_pictures(%{assigns: assigns} = socket) do
    start_async(socket, :load_pictures, fn -> load_pictures(assigns) end)
  end

  defp highlighted?(socket, %{group_id: group_id}) do
    highlighted?(socket, group_id)
  end

  defp highlighted?(socket, %{id: group_id}) do
    highlighted?(socket, group_id)
  end

  defp highlighted?(%{assigns: %{pictures: %{results: results}}}, group_id) do
    case SelectableList.highlighted_item(results) do
      %{group_id: ^group_id} ->
        true

      _ ->
        false
    end
  end
end
