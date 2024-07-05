defmodule GalerieWeb.Components.Layouts do
  use Phoenix.Component
  use GalerieWeb.Components.Routes
  alias GalerieWeb.Components.Ui

  import GalerieWeb.Gettext

  embed_templates("layouts/*")

  @default "flex flex-col bg-gray-200 border-l-4 py-3 px-2 mb-2 rounded-r-md"
  @class %{
    info: "#{@default} border-yellow-600 text-gray-800",
    error: "#{@default} border-red-800 text-gray-800"
  }
  attr(:message, :string, required: true)
  attr(:type, :atom, required: true)

  def message(%{type: type} = assigns) do
    assigns = assign(assigns, :class, Map.fetch!(@class, type))

    ~H"""
    <%= if @message do %>
      <div class={@class}>
        <%= for message <- List.wrap(@message) do %>
          <span class=""><%= message %></span>
        <% end %>
      </div>
    <% end %>
    """
  end

  def logo(assigns) do
    ~H"""
    <h1 class="text-4xl text-pink-400 font-bold uppercase tracking-wide">Galerie</h1>
    """
  end
end
