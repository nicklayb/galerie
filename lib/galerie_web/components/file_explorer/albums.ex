defmodule GalerieWeb.Components.FileExplorer.Albums do
  use GalerieWeb, :component
  alias Galerie.Albums
  alias GalerieWeb.Html
  alias GalerieWeb.Components.FileExplorer
  alias GalerieWeb.Components.Icon

  attr(:explorer, Galerie.Explorer, required: true)
  attr(:on_back, :string, required: true)
  attr(:on_click, :string, required: true)
  attr(:on_edit, :string, default: nil)
  attr(:highlighted, :list, default: [])

  def render(assigns) do
    ~H"""
      <FileExplorer.render explorer={@explorer} on_back={@on_back}>
        <:empty>
          <Icon.left_chevron width="20" height="20" class="mr-1" /> <%= gettext("Back") %>
        </:empty>
        <:branch :let={%Albums.AlbumFolder{id: id, name: name}}>
          <div class={Html.class("flex justify-between items-center group px-2 py-1 cursor-pointer", {id in @highlighted, "bg-gray-300", "hover:bg-gray-200"})} phx-click={@on_click} phx-value-type="branch" phx-value-id={id}>
            <.label 
              on_edit={@on_edit}
              record_id={id}
              record_type="branch"
              icon={:folder}
              label={name}
            />
            <div class="flex items-center">
              <Icon.right_chevron width="20" height="20" />
            </div>
          </div>
        </:branch>
        <:leaf :let={%Albums.Album{id: id, name: name, hide_from_main_library: hide_from_main_library}}>
          <div class={Html.class("flex px-2 py-1 items-center justify-between group cursor-pointer", {id in @highlighted, "bg-gray-300", "hover:bg-gray-200"})} phx-click={@on_click} phx-value-type="leaf" phx-value-id={id}>
            <.label 
              on_edit={@on_edit}
              record_id={id}
              record_type="leaf"
              icon={:picture}
              label={name}
            />
            <div class="flex items-center">
              <%= if hide_from_main_library do %>
                <div class="text-true-gray-400">
                  <Icon.eye_disabled width="22" height="22" />
                </div>
              <% end %>
            </div>
          </div>
        </:leaf>
      </FileExplorer.render>
    """
  end

  defp label(%{on_edit: on_edit} = assigns) do
    assigns = assign(assigns, :editable?, is_binary(on_edit))

    ~H"""
      <div class="flex itemx-center">
        <%= if @editable? do %>
          <div class="pr-1 hidden group-hover:block group" phx-click={@on_edit} phx-value-type={@record_type} phx-value-id={@record_id}>
            <Icon.gear width="20" height="20"/>
          </div>
        <% end %>
        <div class={Html.class("pr-1", {@editable?, "group-hover:hidden group"})}>
          <Icon.icon icon={@icon} width="20" height="20" />
        </div>
        <%= @label %>
      </div>
    """
  end
end
