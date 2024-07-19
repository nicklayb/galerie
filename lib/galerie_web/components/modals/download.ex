defmodule GalerieWeb.Components.Modals.Download do
  use Phoenix.LiveComponent
  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal

  @defaults [
    type: :jpeg
  ]
  def mount(socket) do
    socket =
      socket
      |> assign(@defaults)
      |> assign(:types,
        jpeg: gettext("JPEG"),
        original: gettext("Original")
      )

    {:ok, socket}
  end

  def handle_event("change-type", %{"value" => value}, socket) do
    socket = assign(socket, :type, String.to_existing_atom(value))
    {:noreply, socket}
  end

  def render(assigns) do
    assigns =
      assigns
      |> update(:selectable_list, fn selectable_list ->
        SelectableList.selected_items(selectable_list, fn {_, item} -> item end)
      end)
      |> then(&assign(&1, :count, length(&1.selectable_list)))
      |> assign_download_link()

    ~H"""
    <div class="relative">
      <Modal.modal>
        <:header>
          <%= gettext("Download %{count} files", count: @count) %>
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
              <div class="text-sm pl-1"><%= gettext("Format") %></div>
              <ul class="text-right">
                <%= for {type, label} <- @types do %>
                  <li>
                    <label>
                      <%= label %>
                      <input type="radio" name="type" value={type} phx-click="change-type" phx-target={@myself} checked={type == @type}>
                    </label>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </:body>
        <:footer class="text-right">
          <Form.button href={@download_link} target="_blank">
            <%= gettext("Download") %>
          </Form.button>
        </:footer>
      </Modal.modal>
    </div>
    """
  end

  defp assign_download_link(assigns) do
    assign(
      assigns,
      :download_link,
      ~p(/download?#{[pictures: Enum.map(assigns.selectable_list, & &1.id), type: assigns.type]})
    )
  end
end
