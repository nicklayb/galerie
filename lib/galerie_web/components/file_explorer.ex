defmodule GalerieWeb.Components.FileExplorer do
  use Phoenix.Component

  import GalerieWeb.Gettext

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  attr(:explorer, Galerie.Explorer, required: true)
  attr(:on_back, :string, required: true)

  slot(:empty, required: true)
  slot(:branch, required: true)
  slot(:leaf, required: true)

  def render(%{explorer: %Galerie.Explorer{parent: parent, items: items}} = assigns) do
    assigns =
      assigns
      |> assign(:parent, parent)
      |> assign(:items, items)

    ~H"""
    <div class={Html.class("flex items-center px-2 py-1 rounded-md items-center", {is_nil(@parent), "text-gray-400", "hover:bg-gray-200 cursor-pointer"})} phx-click={if not is_nil(@parent), do: @on_back}>
      <Icon.left_chevron width="20" height="20" class="mr-1" /> <%= gettext("Back") %>
    </div>
    <Ui.list items={@items}>
      <:empty>
        <%= render_slot(@empty) %>
      </:empty>
      <:item :let={item}>
        <%= case item do %>
          <% {:branch, branch} -> %>
            <%= render_slot(@branch, branch) %>

          <% {:leaf, leaf} -> %>
            <%= render_slot(@leaf, leaf) %>
        <% end %>
      </:item>
    </Ui.list>
    """
  end
end
