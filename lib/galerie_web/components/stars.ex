defmodule GalerieWeb.Components.Stars do
  use Phoenix.Component

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Html

  attr(:class, :string, default: "")
  attr(:icon_size, :integer, default: 20)
  attr(:star_class, :string, default: "")
  attr(:highlight_color, :string, default: "text-yellow-400")
  attr(:value, :integer, required: true)
  attr(:range, Range, required: true)
  attr(:rest, :global)

  def render(assigns) do
    ~H"""
    <div class={Html.class("flex flex-row justify-evenly", @star_class)}>
      <%= for rating <- @range do %>
        <div class={Html.class("cursor-pointer", @star_class)} phx-value-rating={rating} {@rest}>
          <Icon.star width={@icon_size} height={@icon_size} class={Html.class([{not is_nil(@value) and @value >= rating, @highlight_color, "text-gray-300"}])}/>
        </div>
      <% end %>
    </div>
    """
  end
end
