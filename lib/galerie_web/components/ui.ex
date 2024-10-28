defmodule GalerieWeb.Components.Ui do
  use Phoenix.Component

  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Html

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)
  attr(:rest, :global)

  @default_class "text-pink-600"
  def button(assigns) do
    assigns = update(assigns, :class, &Html.class(@default_class, &1))

    ~H"""
    <button type="button" class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr(:href, :string, required: true)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)
  attr(:rest, :global)

  @default_class "text-pink-600"
  def link(assigns) do
    assigns = update(assigns, :class, &Html.class(@default_class, &1))

    ~H"""
    <a href={@href} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  attr(:href, :string, required: true)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)
  attr(:rest, :global)

  def link_local(assigns) do
    assigns = update(assigns, :class, &Html.class(@default_class, &1))

    ~H"""
    <Phoenix.Component.link navigate={@href} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

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
      <div class="flex w-full items-center justify-center">
        <Icon.loading />
      </div>
    <% else %>
      <%= if assigns[:inner_block], do: render_slot(@inner_block) %>
    <% end %>
    """
  end

  attr(:checked, :boolean, required: true)
  attr(:on_select, :string, default: nil)
  attr(:on_deselect, :string, default: nil)

  attr(:class, :string, default: "")
  attr(:size, :string, default: "h-7 w-7")

  attr(:check_class, :string,
    default: "text-white border-2 flex items-center justify-center rounded-full cursor-pointer"
  )

  attr(:rest, :global)

  def select_marker(assigns) do
    ~H"""
    <%= if @checked do %>
      <div class={Html.class(@check_class, ["border-pink-600 hover:border-pink-600 bg-pink-600", @size, @class])} phx-click={@on_deselect} {@rest}>
        <Icon.check width="15" height="15" />
      </div>
    <% else %>
      <div class={Html.class(@check_class, ["border-gray-200 hover:border-pink-600", @size, @class])} phx-click={@on_select} {@rest} />
    <% end %>
    """
  end

  attr(:items, :list, required: true)
  slot(:item, required: true)
  slot(:empty, required: false)
  slot(:bottom, required: false)

  def list(assigns) do
    ~H"""
    <%= if Enum.any?(@items) do %>
      <%= for item <- @items do %>
        <%= render_slot(@item, item) %>
      <% end %>
      <%= render_slot(@bottom) %>
    <% else %>
      <%= render_slot(@empty) %>
    <% end %>
    """
  end

  attr(:on_click, :string, required: true)
  attr(:expanded, MapSet, required: true)
  attr(:key, :string, required: true)

  slot(:title, required: true) do
    attr(:class, :any)
  end

  slot(:body, required: true)

  def expandable(%{title: [title_assigns], key: key, expanded: expanded} = assigns) do
    assigns =
      assigns
      |> assign(:expanded?, MapSet.member?(expanded, key))
      |> assign(:title_class, Map.get(title_assigns, :class, ""))

    ~H"""
    <div class="last:border-b last:border-b-gray-400 border-t border-t-gray-400">
      <div class={Html.class("w-full cursor-pointer bg-gray-200 items-center flex flex-row py-1", @title_class)} phx-click={@on_click} phx-value-key={@key}>
        <div class="flex">
          <%= if @expanded? do %>
            <Icon.down_chevron width="20" height="20"/>
          <% else %>
            <Icon.right_chevron width="20" height="20"/>
          <% end %>
        </div>
        <%= render_slot(@title) %>
      </div>
      <%= if @expanded? do %>
        <%= render_slot(@body) %>
      <% end %>
    </div>
    """
  end
end
