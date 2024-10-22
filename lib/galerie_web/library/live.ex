defmodule GalerieWeb.Library.Live do
  use GalerieWeb, :live_view

  require Galerie.PubSub
  require Logger

  alias Galerie.Albums
  alias Galerie.Albums.Album
  alias Galerie.Folders
  alias Galerie.Jobs.Importer
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Pictures.PictureItem
  alias Galerie.Repo
  alias Galerie.Repo.Page

  alias GalerieWeb.Components.Dropzone
  alias GalerieWeb.Components.FileExplorer
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Components.Picture
  alias GalerieWeb.Components.Ui

  alias Phoenix.LiveView.AsyncResult

  import GalerieWeb.Gettext

  @picture_viewer_id "pictureViewer"
  @picture_filter_id "pictureFilter"

  @defaults %{
    picture_viewer_id: @picture_viewer_id,
    picture_filter_id: @picture_filter_id,
    updating: true,
    pictures: nil,
    filter_selected: false,
    modal: nil,
    jobs: %{},
    folders: [],
    filters: [],
    selected_album: nil,
    selected_album_id: nil,
    without_albums?: false
  }

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(@defaults)
      |> setup_upload()
      |> start_async(:load_folders, fn -> Folders.get_user_folders(current_user) end)
      |> start_async(:load_jobs, fn -> {true, Galerie.ObanRepo.pending_jobs()} end)
      |> assign_async(:album_explorer, fn ->
        {:ok, %{album_explorer: Albums.explore_user_albums(current_user)}}
      end)

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
    album_ids =
      if assigns.without_albums? do
        :without_albums
      else
        List.wrap(assigns.selected_album_id)
      end

    query_options = [
      {:album_ids, album_ids}
      | assigns.filters
    ]

    assigns.folders
    |> Enum.Extra.field(:id)
    |> Pictures.list_pictures(query_options)
    |> Repo.Page.map_results(&SelectableList.new/1)
  end

  def handle_event("create-album-folder", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.CreateAlbumFolder,
         current_user: socket.assigns.current_user, current_folder_id: current_folder_id(socket)}
      )

    {:noreply, socket}
  end

  def handle_event("create-album", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.CreateAlbum,
         current_user: socket.assigns.current_user, current_folder_id: current_folder_id(socket)}
      )

    {:noreply, socket}
  end

  def handle_event("album-explorer:enter", %{"id" => id}, socket) do
    socket =
      update_async_result(
        socket,
        :album_explorer,
        &Galerie.Explorer.enter(&1, id)
      )

    {:noreply, socket}
  end

  def handle_event("album-explorer:back", _, socket) do
    socket =
      update_async_result(
        socket,
        :album_explorer,
        &Galerie.Explorer.back(&1)
      )

    {:noreply, socket}
  end

  def handle_event("album-explorer:set-active", %{"id" => id}, socket) do
    {selected_album, selected_album_id} =
      if id == socket.assigns.selected_album_id do
        {nil, nil}
      else
        item = Galerie.Explorer.find_by_identity(socket.assigns.album_explorer.result, id)
        {item, id}
      end

    socket =
      socket
      |> assign(:selected_album, selected_album)
      |> assign(:selected_album_id, selected_album_id)
      |> reload_pictures()

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

  def handle_event("selection_bar:filter-selected", _, socket) do
    socket = update(socket, :filter_selected, &(not &1))

    {:noreply, socket}
  end

  def handle_event("filter:edit-album-folder", %{"album_folder_id" => album_folder_id}, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.EditAlbumFolder,
         [album_folder_id: album_folder_id, current_user: socket.assigns.current_user]}
      )

    {:noreply, socket}
  end

  def handle_event("filter:edit-album", %{"album_id" => album_id}, socket) do
    socket =
      assign(
        socket,
        :modal,
        {GalerieWeb.Components.Modals.EditAlbum,
         [album_id: album_id, current_user: socket.assigns.current_user]}
      )

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
      update_pictures(socket, &SelectableList.deselect_by_index(&1, String.to_integer(index)))

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
        {GalerieWeb.Components.Modals.EditPictures,
         [
           selectable_list: socket.assigns.pictures.results,
           current_user: socket.assigns.current_user
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

  def handle_event("viewer:keyup", %{"key" => "c"}, socket) do
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

  @rating_keys Enum.map(Group.rating_range(), &to_string/1)

  def handle_event("viewer:keyup", %{"key" => key}, socket) when key in @rating_keys do
    %PictureItem{group_id: group_id} =
      SelectableList.highlighted_item(socket.assigns.pictures.results)

    Pictures.update_rating(group_id, String.to_integer(key))

    {:noreply, socket}
  end

  def handle_event("viewer:keyup", _params, socket) do
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

  def handle_event("modal:keyup", %{"key" => "Escape"}, %{assigns: %{modal: modal}} = socket)
      when not is_nil(modal) do
    socket = assign(socket, :modal, nil)

    {:noreply, socket}
  end

  def handle_event("modal:keyup", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("validate_file", %{"_target" => _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:filter_updated, filters}, socket) do
    socket =
      socket
      |> assign(:filters, filters)
      |> reload_pictures()

    {:noreply, socket}
  end

  def handle_info(:close_modal, socket) do
    socket = assign(socket, :modal, nil)
    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :removed_from_album,
          params: %{group: group}
        } = message,
        socket
      ) do
    if highlighted?(socket, group) do
      send_to_viewer(message: message)
    end

    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :metadata_updated,
          params: {updated_metadata, picture}
        } = message,
        socket
      ) do
    if highlighted?(socket, picture) do
      send_to_viewer(message: message)
    end

    send_to_filter(updated_metadata: updated_metadata)

    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :metadata_updated,
          params: [_ | _] = updated_metadata
        },
        socket
      ) do
    send_to_filter(updated_metadata: updated_metadata)

    {:noreply, socket}
  end

  @interesting_messages Picture.Viewer.interesting_messages()
  def handle_info(
        %Galerie.PubSub.Message{
          message: inner_message,
          params: picture
        } = message,
        socket
      )
      when inner_message in @interesting_messages do
    if highlighted?(socket, picture) do
      send_to_viewer(message: message)
    end

    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{
          message: :thumbnail_generated,
          params: %Galerie.Pictures.Picture{}
        },
        socket
      ) do
    Galerie.PubSub.broadcast(
      {:sessions, socket.assigns.live_session_id},
      {:update_notification,
       {:new_pictures,
        fn params ->
          count = Map.get(params, :count, 0) + 1

          {:info, gettext("%{count} new pictures", count: count),
           key: :new_pictures, params: %{count: count}}
        end}}
    )

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

  @album_message ~w(album_created album_deleted album_updated)a
  @album_folder_message ~w(album_folder_created album_folder_deleted album_folder_updated)a
  def handle_info(
        %Galerie.PubSub.Message{
          message: album_message
        },
        socket
      )
      when album_message in @album_message or album_message in @album_folder_message do
    socket = reload_explorer(socket)

    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{message: message}, socket) do
    Logger.warning("[#{inspect(__MODULE__)}] [handle_info] [unhandled_pub_sub] #{message}")
    {:noreply, socket}
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

  defp subscribe(%PictureItem{group_id: group_id}) do
    Galerie.PubSub.subscribe({Galerie.Pictures.Picture.Group, group_id})
  end

  defp subscribe(_), do: :noop

  defp unsubscribe(%PictureItem{group_id: group_id}) do
    Galerie.PubSub.unsubscribe({Galerie.Pictures.Picture.Group, group_id})
  end

  defp unsubscribe(_), do: :noop

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
    previous_highlighted_item = SelectableList.highlighted_item(socket.assigns.pictures.results)

    socket
    |> update(:pictures, fn page -> Page.map_results(page, function) end)
    |> clear_filter_selected_if_none_selected()
    |> tap(&resubscribe(&1, previous_highlighted_item))
  end

  defp resubscribe(
         %{assigns: %{pictures: %Page{results: %SelectableList{} = results}}},
         previous_highlighted_item
       ) do
    unsubscribe(previous_highlighted_item)

    results
    |> SelectableList.highlighted_item()
    |> subscribe()
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

  defp send_to_filter(assigns) do
    send_update(self(), Picture.Filter, [{:id, @picture_filter_id} | assigns])
  end

  defp send_to_viewer(assigns) do
    send_update(self(), Picture.Viewer, [{:id, @picture_viewer_id} | assigns])
  end

  defp reload_explorer(socket) do
    update_async_result(
      socket,
      :album_explorer,
      fn
        %Galerie.Explorer{path: path} ->
          socket.assigns.current_user
          |> Albums.explore_user_albums()
          |> Galerie.Explorer.enter(Enum.reverse(path))
      end
    )
  end

  defp update_async_result(socket, key, function) do
    update(socket, key, &%AsyncResult{&1 | result: function.(&1.result)})
  end

  defp current_folder_id(%{
         assigns: %{
           album_explorer: %AsyncResult{
             result: %Galerie.Explorer{path: [current_folder_id | _]}
           }
         }
       }) do
    current_folder_id
  end

  defp current_folder_id(_), do: nil
end
