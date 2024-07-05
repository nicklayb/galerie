defmodule GalerieWeb.Components.Breadcrumb do
  use GalerieWeb.Components.Routes
  use Phoenix.LiveComponent

  def update(%{uri: uri}, %{assigns: %{uri: uri}} = socket), do: {:ok, socket}

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:breadcrumbs, fn -> [] end)
      |> start_async(:update_breadcrumb, fn -> load_breadcrumb(assigns) end)

    {:ok, socket}
  end

  defp load_breadcrumb(%{uri: %URI{path: path}, params: params, current_user: current_user}) do
    case extract_breadcrumbs(path, params, current_user) do
      [_ | _] = breadcrumbs -> breadcrumbs
      _ -> put_item([], {nil, "Not found"})
    end
  end

  def handle_async(:update_breadcrumb, {:ok, [_ | _] = breadcrumbs}, socket) do
    {:noreply, assign(socket, :breadcrumbs, breadcrumbs)}
  end

  def handle_async(:update_breadcrumb, _, socket) do
    {:noreply, socket}
  end

  defp extract_breadcrumbs("/app/home" <> _, _, _), do: put_item([], {nil, "Home"})

  defp extract_breadcrumbs("/app/" <> _, _, _), do: put_item([], {nil, "Not found"})

  defp put_item([], {_, top_leve_item}), do: [{nil, top_leve_item}]
  defp put_item(acc, {_, _} = item), do: [item | acc]

  def render(assigns) do
    ~H"""
      <div class="flex-initial text-sm">
        <%= for part <- Enum.intersperse(@breadcrumbs, :splitter) do %>
          <%= case part do %>
            <% {nil, name} -> %>
              <span class="text-purple-400"><%= name %></span>

            <% {path, name} -> %>
              <.link navigate={path} class="text-true-gray-200 hover:text-purple-400"><%= name %></.link>

            <% :splitter -> %>
              <span class="text-true-gray-500 px-1">/</span>
          <% end %>
        <% end %>
      </div>
    """
  end
end
