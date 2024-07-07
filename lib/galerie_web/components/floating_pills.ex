defmodule GalerieWeb.Components.FloatingPills do
  use Phoenix.Component

  alias GalerieWeb.Components.Icon

  slot(:inner_block)

  def pills(assigns) do
    ~H"""
    <div class="z-30 fixed bottom-0 right-0 m-6 mb-4 text-right">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:visible, :boolean, required: true)
  attr(:text, :string, required: true)
  attr(:pill_class, :string, default: "bg-pink-400")
  attr(:button_class, :string, default: "hover:bg-pink-600")

  slot(:button) do
    attr(:icon, :atom, required: true)
    attr(:phx_click, :string, required: true)
    attr(:width, :string)
    attr(:height, :string)
    attr(:class, :string)
  end

  def pill(assigns) do
    ~H"""
    <%= if @visible do %>
      <div class={"inline-flex items-center right-0 rounded-full shadow-lg px-4 py-2 justify-between text-white " <> @pill_class }>
        <div><%= @text %></div>
        <%= for button <- @button do %>
        <span class={"ml-2 w-5 cursor-pointer h-5 rounded-full flex items-center justify-center " <> @button_class <> " " <> Map.get(button, :class, "")} phx-click={button.phx_click}>
          <Icon.icon icon={button.icon} width={Map.get(button, :width, "4")} height={Map.get(button, :height, "4")}/>
        </span>
        <% end %>
      </div>
    <% end %>
    """
  end
end
