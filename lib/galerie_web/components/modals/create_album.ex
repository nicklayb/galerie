defmodule GalerieWeb.Components.Modals.CreateAlbum do
  use GalerieWeb, :live_component

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

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_folders()
      |> assign_form(%{album_folder_id: Map.get(assigns, :current_folder_id)})
      |> tap(fn k ->
        IO.inspect(k.assigns)
      end)

    {:ok, socket}
  end

  defp assign_folders(socket) do
    folders = Albums.user_album_folders(socket.assigns.current_user)
    assign(socket, :folders, folders)
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
      case UseCase.execute(socket, Galerie.Albums.UseCase.CreateAlbum, album) do
        {:ok, _} ->
          send(self(), :close_modal)
          socket

        {:error, :album, %Ecto.Changeset{} = changeset, _} ->
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
