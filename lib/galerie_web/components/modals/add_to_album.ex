defmodule GalerieWeb.Components.Modals.AddToAlbum do
  use Phoenix.LiveComponent
  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext
  alias Galerie.Albums
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Components.Modals.AddToAlbum.Form, as: AddToAlbumForm

  @defaults []
  def mount(socket) do
    socket = assign(socket, @defaults)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_selectable_list()

    {:ok, socket}
  end

  def handle_event("change", %{"add_to_album" => %{"album_ids" => album_ids}}, socket) do
    socket =
      assign(
        socket,
        :form,
        AddToAlbumForm.new(%{group_ids: socket.assigns.group_ids, album_ids: album_ids})
      )

    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    socket.assigns.form
    |> AddToAlbumForm.submit()
    |> Result.map(fn %{group_ids: group_ids, album_ids: album_ids} ->
      Albums.attach_picture_groups_to_albums(album_ids, group_ids)
    end)
    |> Result.map(fn _ ->
      send(self(), :sync_albums)
      send(self(), :close_modal)
    end)

    {:noreply, socket}
  end

  defp assign_selectable_list(%{assigns: %{selectable_list: %SelectableList{}}} = socket) do
    socket
    |> update(:selectable_list, fn selectable_list ->
      SelectableList.selected_items(selectable_list, fn {_, item} -> item end)
    end)
    |> then(&assign(&1, :count, length(&1.assigns.selectable_list)))
    |> then(fn socket ->
      group_ids = Enum.map(socket.assigns.selectable_list, & &1.group_id)

      socket
      |> assign(:group_ids, group_ids)
      |> assign(:form, AddToAlbumForm.new(%{group_ids: group_ids}))
    end)
  end

  defp assign_selectable_list(socket) do
    socket
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} as={:add_to_album} class="relative" phx-change="change" phx-submit="save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            <%= gettext("Add %{count} files to albums", count: @count) %>
          </:header>
          <:body>
            <div class="mb-2">
              <div class="mb-2">
                <div class="text-sm pl-1"><%= gettext("Files") %></div>
                <ul class="overflow-y-auto max-h-60 shadow-inner">
                  <%= for item <- @selectable_list do %>
                    <li class="px-2 py-1 first:rounded-t-md last:rounded-b-md border-b-0 last:border-b border border-true-gray-300">
                      <%= item.name %>
                      <Form.hidden field={@form[:group_ids]} multiple={true} value={item.group_id} />
                    </li>
                  <% end %>
                </ul>
              </div>
              <div class="mb-2">
                <div class="text-sm pl-1"><%= gettext("Albums") %></div>
                <div class="">
                  <ul>
                    <%= for {_, album} <- @albums do %>
                      <li class="border border-true-gray-300 border-b-0 py-1 pl-1 pr-2 last:border-b first:rounded-t-md last:rounded-b-md">
                        <Form.checkbox label={album.name} field={@form[:album_ids]} checked={album.id in @form[:album_ids].value} multiple={true} value={album.id} element_class="flex flex-row justify-between items-center" />
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
            </div>
          </:body>
          <:footer class="text-right">
            <Form.button type={:submit} phx-target={@myself}>
              <%= gettext("Add") %>
            </Form.button>
          </:footer>
        </Modal.modal>
      </.form>
    </div>
    """
  end
end
