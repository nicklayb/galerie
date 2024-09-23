defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext

  alias Galerie.Pictures.PictureItem
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  attr(:pictures, :list, required: true)
  attr(:selected_pictures, MapSet, default: %MapSet{})
  attr(:filter_selected, :boolean, default: false)

  def grid(%{pictures: pictures} = assigns) do
    filtered_pictures =
      if assigns.filter_selected do
        SelectableList.selected_items(pictures)
      else
        pictures
      end

    assigns = assign(assigns, :filtered_pictures, filtered_pictures)

    ~H"""
    <div class="grid grid-cols-1 tablet:grid-cols-2 laptop:grid-cols-4 desktop:grid-cols-6 gap-4 m-auto mb-2">
      <%= for {index, picture} <- @filtered_pictures do %>
        <.thumbnail picture={picture} checked={SelectableList.index_selected?(@pictures, index)} index={index}/>
      <% end %>
    </div>
    """
  end

  attr(:selectable_list, SelectableList, required: true)
  slot(:inner_block, required: true)

  def selection_bar(assigns) do
    ~H"""
    <div class="p-2 h-10 flex items-center justify-between">
      <div class="flex-1 flex">
        <%= if SelectableList.any_selected?(@selectable_list) do %>
          <%= render_slot(@inner_block) %>
        <% end %>
      </div>
      <div class="flex items-center justify-center flex-initial">
        <%= gettext("%{count} selected", count: Enum.count(@selectable_list.selected_indexes)) %>
        <Ui.link_local href={~p(/app/settings/access_links)} class="ml-2">
          <Icon.gear width="30" height="30" />
        </Ui.link_local>
      </div>
    </div>
    """
  end

  attr(:action, :string, required: true)
  attr(:title, :string, default: "")
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def selection_button(assigns) do
    ~H"""
    <Form.button phx-click={@action} size={:small} style={:outline} class={Html.class("ml-1", @class)} title={@title}>
      <%= render_slot(@inner_block) %>
    </Form.button>
    """
  end

  attr(:link, :string, required: true)
  attr(:title, :string, default: "")
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def selection_link(assigns) do
    ~H"""
    <Form.button href={@link} size={:small} style={:outline} class={Html.class("ml-1", @class)} title={@title} target="_blank">
      <%= render_slot(@inner_block) %>
    </Form.button>
    """
  end

  attr(:picture, PictureItem, required: true)
  attr(:index, :integer, required: true)
  attr(:checked, :boolean, default: false)

  def thumbnail(assigns) do
    ~H"""
    <div class={Html.class("relative transition cursor-pointer select-none group", {@checked, "scale-90"})} phx-click="picture-click" phx-value-picture_id={@picture.id} phx-value-index={@index}>
      <img class={Html.class("h-full max-h-72 w-full rounded-md shadow-md border-4 group object-cover", {@checked, "border-pink-500", "border-true-gray-300"})} src={~p(/pictures/#{@picture.id}?#{[type: "thumb"]})} />

      <div class={Html.class("w-full h-full group-hover:bg-gray-500/40 transition p-4 absolute z-10 top-0", [{not @checked, "opacity-0 group-hover:opacity-100"}])}>
        <Ui.select_marker checked={@checked}  on_select="select-picture" on_deselect="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@index} />
      </div>
    </div>
    """
  end
end
