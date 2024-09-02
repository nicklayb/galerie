defmodule GalerieWeb.Components.Modals.CreateAlbum do
  use Phoenix.LiveComponent
  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext
  alias Galerie.Albums
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal

  @defaults []
  def mount(socket) do
    socket =
      socket
      |> assign(@defaults)
      |> assign_form()

    {:ok, socket}
  end

  defp assign_form(socket, params \\ %{})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, params) do
    assign_form(socket, Galerie.Albums.Album.changeset(params))
  end

  def handle_event("change", %{"album" => album}, socket) do
    socket = assign_form(socket, album)

    {:noreply, socket}
  end

  def handle_event("save", %{"album" => album}, socket) do
    socket =
      case Albums.create_album(album, user: socket.assigns.current_user) do
        {:ok, _} ->
          send(self(), :close_modal)
          socket

        {:error, :album, %Ecto.Changeset{} = changeset} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} class="relative" phx-change="change" phx-submit="save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            <%= gettext("Create album") %>
          </:header>
          <:body>
            <Form.text_input field={@form[:name]}>
              <:label><%= gettext("Album name") %></:label>
            </Form.text_input>
          </:body>
          <:footer class="text-right">
            <Form.button type={:submit} phx-target={@myself}>
              <%= gettext("Create") %>
            </Form.button>
          </:footer>
        </Modal.modal>
      </.form>
    </div>
    """
  end
end
