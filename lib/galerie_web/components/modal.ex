defmodule GalerieWeb.Components.Modal do
  use Phoenix.Component

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Html

  def render(assigns) do
    ~H"""
    <%= case @component do %>
      <% {component, component_assigns} -> %>
        <.overlay>
          <.live_component id="modal" module={component} {component_assigns} />
        </.overlay>

      <% nil -> %>

      <% component when is_atom(component) -> %>
        <.overlay>
          <.live_component id="modal" module={component}/>
        </.overlay>
    <% end %>
    """
  end

  slot(:inner_block, required: true)

  def overlay(assigns) do
    ~H"""
    <div class="h-full w-full fixed top-0 left-0 bg-gray-800/90 transition-all z-70 absolute fade-in" phx-window-keyup="modal:keyup">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot(:header, required: false) do
    attr(:class, :string)
  end

  slot(:body, required: true) do
    attr(:class, :string)
  end

  slot(:footer, required: false) do
    attr(:class, :string)
  end

  def modal(assigns) do
    ~H"""
    <div class="bg-true-gray-100 absolute top-0 right-0 w-full max-w-[400px] mt-4 mr-4 rounded-lg shadow-lg transition-all slide-left">
      <div class="absolute top-0 right-0 p-4 cursor-pointer" phx-click="modal:close">
        <Icon.cross width="12" height="12" />
      </div>
      <%= with [slot | _] <- @header do %>
        <div class={Html.class("text-xl font-bold border-b border-b-true-gray-200 p-2", Map.get(slot, :class))}>
          <%= render_slot(slot) %>
        </div>
      <% end %>
      <%= with [slot | _] <- @body do %>
        <div class={Html.class("p-2", Map.get(slot, :class))}>
          <%= render_slot(slot) %>
        </div>
      <% end %>
      <%= with [slot | _] <- @footer do %>
        <div class={Html.class("border-t border-t-true-gray-200 p-2", Map.get(slot, :class))}>
          <%= render_slot(slot) %>
        </div>
      <% end %>
    </div>
    """
  end
end
