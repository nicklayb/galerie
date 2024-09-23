defmodule GalerieWeb.Components.Layouts do
  use Phoenix.Component
  use GalerieWeb.Components.Routes
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

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

  defp settings_nav(assigns) do
    IO.inspect(assigns)

    items =
      Enum.sort_by(
        [
          %{title: gettext("Access links"), path: ~p(/app/settings/access_links)},
          %{title: gettext("Users"), path: ~p(/app/settings/users)}
        ],
        & &1.title
      )

    assigns =
      assign(assigns, :items, items)

    ~H"""
    <nav class="flex flex-col w-80 p-4">
      <.settings_nav_item path={~p(/app)} title={gettext("Back to Galerie")} class="pl-1">
        <div class="flex items-center">
          <Icon.left_chevron width="30" height="30" />
          <%= gettext("Back to Galerie") %>
        </div>
      </.settings_nav_item>
      <%= for %{title: title, path: path} <- @items do %>
        <.settings_nav_item title={title} path={path} active={String.starts_with?(@uri.path, path)}>
          <%= title %>
        </.settings_nav_item>
      <% end %>
    </nav>
    """
  end

  @default_class "p-3 rounded-lg font-bold mb-2"
  attr(:class, :string, default: "")
  attr(:active, :boolean, default: false)

  defp settings_nav_item(assigns) do
    assigns = update(assigns, :class, fn class -> Html.class(@default_class, class) end)

    ~H"""
    <Ui.link_local href={@path} class={Html.class(@class, {@active, "bg-pink-700 text-white", "text-true-gray-700 hover:bg-true-gray-200"})} data-active={if @active, do: "true", else: "false"}>
      <%= render_slot(@inner_block) %>
    </Ui.link_local>
    """
  end
end
