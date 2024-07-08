defmodule GalerieWeb.Components.Ui do
  use Phoenix.Component

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Html

  def logo(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold uppercase tracking-wide">Galerie</h1>
    """
  end

  slot(:inner_block, required: false)
  attr(:loading, :boolean, default: false)

  def loading(assigns) do
    ~H"""
    <%= if @loading do %>
      <div class="">
        <Icon.loading />
      </div>
    <% else %>
      <%= if assigns[:inner_block], do: render_slot(@inner_block) %>
    <% end %>
    """
  end

  attr(:checked, :boolean, required: true)
  attr(:on_select, :string, required: true)
  attr(:on_deselect, :string, required: true)

  attr(:class, :string, default: "")

  attr(:check_class, :string,
    default:
      "text-white border-2 w-7 h-7 flex items-center justify-center rounded-full cursor-pointer"
  )

  attr(:rest, :global)

  def select_marker(assigns) do
    ~H"""
    <%= if @checked do %>
      <div class={Html.class(@check_class, ["border-pink-600 hover:border-pink-600 bg-pink-600", @class])} phx-click={@on_deselect} {@rest}>
        <Icon.check width="15" height="15" />
      </div>
    <% else %>
      <div class={Html.class(@check_class, ["border-gray-200 hover:border-pink-600", @class])} phx-click={@on_select} {@rest} />
    <% end %>
    """
  end
end
