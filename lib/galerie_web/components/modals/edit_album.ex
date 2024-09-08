defmodule GalerieWeb.Components.Modals.EditAlbum do
  alias GalerieWeb.Core.Notifications
  use GalerieWeb, :live_component

  alias Galerie.Albums.Album
  alias Galerie.Form.Albums.EditAlbumForm
  alias Galerie.Repo
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()

    {:ok, socket}
  end

  defp assign_form(socket) do
    album = Repo.get!(Album, socket.assigns.album_id)

    socket
    |> assign(:album, album)
    |> assign(
      :form,
      EditAlbumForm.new(%{
        id: album.id,
        name: album.name,
        hide_from_main_library: album.hide_from_main_library
      })
    )
  end

  def handle_event("edit_album:change", %{"edit_album" => edit_album}, socket) do
    socket = assign(socket, :form, EditAlbumForm.new(edit_album))
    {:noreply, socket}
  end

  def handle_event("edit_album:save", %{"edit_album" => params}, socket) do
    socket =
      with {:ok, form} <- EditAlbumForm.submit(params),
           {:ok, _result} <- UseCase.execute(socket, Galerie.Albums.UseCase.EditAlbum, form) do
        send(self(), :close_modal)
        Notifications.notify(socket, :info, gettext("Album edited successfully"))
      else
        {:error, :album, %Ecto.Changeset{} = changeset, _} ->
          assign(socket, :form, EditAlbumForm.new(changeset))

        error ->
          IO.inspect(error)

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
