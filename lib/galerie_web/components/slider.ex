defmodule GalerieWeb.Components.Slider do
  use Phoenix.Component

  alias GalerieWeb.Html

  attr(:min, :integer, required: true)
  attr(:max, :integer, required: true)
  attr(:left_value, :integer, required: true)
  attr(:right_value, :integer, required: true)
  attr(:id, :string, required: true)
  attr(:rest, :global)

  @range_class "appearance-none w-full outline-none absolute m-auto top-0 bottom-0 bg-transparent pointer-events-none"
  def double(assigns) do
    assigns = assign(assigns, :range_class, @range_class)

    ~H"""
    <div class="relative" id={@id} phx-hook="DoubleSlider" {@rest}>
      <div class="bg-pink-600 w-20 relative m-auto px-3 rounded-md text-center text-white">
        <span class="left-value">
          <%= @left_value %>
        </span>
        <span>&dash;</span>
        <span class="right-value">
          <%= @right_value %>
        </span>
      </div>
      <div class="w-full h-6 mt-4">
        <div class="w-full h-2 absolute m-auto top-0 bottom-0 rounded-md"></div>
        <input type="range" class={Html.class(@range_class, "left-input")} min={@min} max={@max} value={@left_value}>
        <input type="range" class={Html.class(@range_class, "right-input")} min={@min} max={@max} value={@right_value}>
      </div>
    </div>
    """
  end
end
