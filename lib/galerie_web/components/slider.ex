defmodule GalerieWeb.Components.Slider do
  use Phoenix.Component

  alias GalerieWeb.Html

  attr(:min, :integer, required: true)
  attr(:max, :integer, required: true)
  attr(:left_value, :integer, required: true)
  attr(:right_value, :integer, required: true)
  attr(:id, :string, required: true)
  attr(:label, :string, default: "")
  attr(:rest, :global)

  @range_class ""
  def double(assigns) do
    assigns = assign(assigns, :range_class, @range_class)

    ~H"""
    <div class="double-slider relative" id={@id} phx-hook="DoubleSlider" data-min={@min} data-max={@max} {@rest}>
      <div class="flex justify-between">
        <%= if @label != "" do %>
          <div><%= @label %></div>
        <% end %>
        <div class="">
          <span class="left-value">
            <%= @left_value %>
          </span>
          <span>&dash;</span>
          <span class="right-value">
            <%= @right_value %>
          </span>
        </div>
      </div>
      <div class="w-full h-6 mt-4">
        <.slider_track left_value={@left_value} right_value={@right_value} max={@max} />
        <input type="range" class={Html.class(@range_class, "left-input")} min={@min} max={@max} value={@left_value}>
        <input type="range" class={Html.class(@range_class, "right-input")} min={@min} max={@max} value={@right_value}>
      </div>
    </div>
    """
  end

  @gradient_background_color "#ddd"
  @gradient_highlight_color "pink"
  defp slider_track(assigns) do
    left_percent = trunc(assigns.left_value / assigns.max * 100)
    right_percent = trunc(assigns.right_value / assigns.max * 100)

    assigns =
      assign(
        assigns,
        :gradient,
        "background: linear-gradient(to right, #{@gradient_background_color} #{left_percent}% , #{@gradient_highlight_color} #{left_percent}% , #{@gradient_highlight_color} #{right_percent}%, #{@gradient_background_color} #{right_percent}%)"
      )

    ~H"""
    <div class="w-full h-2 absolute m-auto top-0 bottom-0 rounded-md" style={@gradient}></div>
    """
  end
end
