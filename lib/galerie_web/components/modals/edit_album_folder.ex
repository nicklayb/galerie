defmodule GalerieWeb.Components.Modals.EditAlbumFolder do
  use GalerieWeb, :live_component

  alias Galerie.Albums
  alias Galerie.Albums.AlbumFolder
  alias Galerie.Repo
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Core.Notifications

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_folders()

    {:ok, socket}
  end

  defp assign_folders(socket) do
    folders =
      socket.assigns.current_user
      |> Albums.user_album_folders()
      |> Enum.reject(fn {album_folder_id, _} ->
        album_folder_id == socket.assigns.album_folder.id
      end)

    assign(socket, :folders, folders)
  end

  defp assign_form(socket) do
    album_folder = Repo.get!(AlbumFolder, socket.assigns.album_folder_id)

    socket
    |> assign(:album_folder, album_folder)
    |> assign_form(%{})
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, params) do
    assign_form(socket, AlbumFolder.update_changeset(socket.assigns.album_folder, params))
  end

  def handle_event("edit_album_folder:change", %{"album_folder" => params}, socket) do
    socket = assign_form(socket, params)
    {:noreply, socket}
  end

  def handle_event("edit_album_folder:save", %{"album_folder" => params}, socket) do
    socket =
      case UseCase.execute(
             socket,
             Galerie.Albums.UseCase.EditAlbumFolder,
             Map.Extra.put(params, :album_folder_id, socket.assigns.album_folder.id)
           ) do
        {:ok, _result} ->
          send(self(), :close_modal)
          Notifications.notify(socket, :info, gettext("Folder edited successfully"))

        {:error, :album_folder, %Ecto.Changeset{} = changeset, _} ->
          assign_form(socket, changeset)

        error ->
          Logger.debug("[#{inspect(__MODULE__)}] [edit_album_folder:save] #{error}")

          Notifications.notify(
            socket,
            :error,
            gettext("Error occured while updating the folder")
          )
      end

    {:noreply, socket}
  end

  def handle_event("edit_album_folder:delete", _, socket) do
    socket =
      case GalerieWeb.UseCase.execute(
             socket,
             Galerie.Albums.UseCase.RemoveAlbumFolder,
             socket.assigns.album_folder.id
           ) do
        {:ok, %AlbumFolder{name: name}} ->
          send(self(), :close_modal)
          Notifications.notify(socket, :info, gettext("Folder %{name} deleted", name: name))

        {:error, _, _} ->
          Notifications.notify(
            socket,
            :error,
            gettext("Unable to delete folder %{name}", name: socket.assigns.album_folder.name)
          )
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} class="relative" phx-change="edit_album_folder:change" phx-submit="edit_album_folder:save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            <%= gettext("Edit album folder") %>
          </:header>
          <:body>
            <Form.text_input field={@form[:name]}>
              <:label><%= gettext("Folder name") %></:label>
            </Form.text_input>
            <div>
              <Form.radio_input field={@form[:parent_folder_id]} value="">
                <:label><%= gettext("Root folder") %></:label>
              </Form.radio_input>
              <%= for {id, parts} <- @folders do %>
                <Form.radio_input field={@form[:parent_folder_id]} value={id}>
                  <:label><%= Enum.join(parts, " / ") %></:label>
                </Form.radio_input>
              <% end %>
            </div>
          </:body>
          <:footer class="text-right">
            <Form.hidden field={@form[:id]} value={@form[:id].value}/>
            <Form.button type={:button} style={:danger} phx-target={@myself} phx-click="edit_album_folder:delete">
              <%= gettext("Delete") %>
            </Form.button>
            <Form.button type={:submit} phx-target={@myself}>
              <%= gettext("Update") %>
            </Form.button>
          </:footer>
        </Modal.modal>
      </.form>
    </div>
    """
  end
end
