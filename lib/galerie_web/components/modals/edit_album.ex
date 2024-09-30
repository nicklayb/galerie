defmodule GalerieWeb.Components.Modals.EditAlbum do
  use GalerieWeb, :live_component

  alias Galerie.Albums
  alias Galerie.Albums.Album
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
    folders = Albums.user_album_folders(socket.assigns.current_user)
    assign(socket, :folders, folders)
  end

  defp assign_form(socket) do
    album = Repo.get!(Album, socket.assigns.album_id)

    socket
    |> assign(:album, album)
    |> assign_form(%{})
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, params) do
    assign_form(socket, Album.update_changeset(socket.assigns.album, params))
  end

  def handle_event("edit_album:change", %{"album" => edit_album}, socket) do
    socket = assign_form(socket, edit_album)
    {:noreply, socket}
  end

  def handle_event("edit_album:save", %{"album" => params}, socket) do
    socket =
      case UseCase.execute(
             socket,
             Galerie.Albums.UseCase.EditAlbum,
             Map.Extra.put(params, :album_id, socket.assigns.album.id)
           ) do
        {:ok, _result} ->
          send(self(), :close_modal)
          Notifications.notify(socket, :info, gettext("Album edited successfully"))

        {:error, :album, %Ecto.Changeset{} = changeset, _} ->
          assign_form(socket, changeset)

        error ->
          Logger.debug("[#{inspect(__MODULE__)}] [edit_album:save] #{error}")

          Notifications.notify(
            socket,
            :error,
            gettext("Error occured while updating the album")
          )
      end

    {:noreply, socket}
  end

  def handle_event("edit_album:delete", _, socket) do
    socket =
      case GalerieWeb.UseCase.execute(
             socket,
             Galerie.Albums.UseCase.RemoveAlbum,
             socket.assigns.album.id
           ) do
        {:ok, %Album{name: name}} ->
          send(self(), :close_modal)
          Notifications.notify(socket, :info, gettext("Album %{name} deleted", name: name))

        {:error, _, _} ->
          Notifications.notify(
            socket,
            :error,
            gettext("Unable to delete album %{name}", name: socket.assigns.album.name)
          )
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} class="relative" phx-change="edit_album:change" phx-submit="edit_album:save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            <%= gettext("Edit album") %>
          </:header>
          <:body>
            <Form.text_input field={@form[:name]}>
              <:label><%= gettext("Album name") %></:label>
            </Form.text_input>
            <div class="text-right">
              <Form.checkbox field={@form[:hide_from_main_library]} value="true" checked={@form[:hide_from_main_library].value}>
                <:label><%= gettext("Hide from main library") %></:label>
              </Form.checkbox>
            </div>
            <div>
              <Form.radio_input field={@form[:album_folder_id]} value="">
                <:label><%= gettext("No folder") %></:label>
              </Form.radio_input>
              <%= for {id, parts} <- @folders do %>
                <Form.radio_input field={@form[:album_folder_id]} value={id}>
                  <:label><%= Enum.join(parts, " / ") %></:label>
                </Form.radio_input>
              <% end %>
            </div>
          </:body>
          <:footer class="text-right">
            <Form.hidden field={@form[:id]} value={@form[:id].value}/>
            <Form.button type={:button} style={:danger} phx-target={@myself} phx-click="edit_album:delete">
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
