defmodule GalerieWeb.Components.Modals.AddToAlbum do
  use Phoenix.LiveComponent
  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal

  @defaults []
  def mount(socket) do
    socket =
      socket
      |> assign(@defaults)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="relative">
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
                  <li class="px-2 py-1 first:rounded-t-md last:rounded-b-md border-b-0 last:border-b border border-true-gray-300"><%= item.name %></li>
                <% end %>
              </ul>
            </div>
            <div class="mb-2">
              <div class="text-sm pl-1"><%= gettext("Albums") %></div>
            </div>
          </div>
        </:body>
        <:footer class="text-right">
          <Form.button phx-click="add" phx-target={@myself}>
            <%= gettext("Add") %>
          </Form.button>
        </:footer>
      </Modal.modal>
    </div>
    """
  end
end
