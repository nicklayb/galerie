defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext

  alias Galerie.Pictures.PictureItem
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  attr(:pictures, :list, required: true)
  attr(:selected_pictures, MapSet, default: %MapSet{})
  attr(:filter_selected, :boolean, default: false)

  def grid(%{pictures: pictures} = assigns) do
    filtered_pictures =
      if assigns.filter_selected do
        Enum.filter(pictures, &MapSet.member?(assigns.selected_pictures, &1.id))
      else
        pictures
      end

    assigns = assign(assigns, :filtered_pictures, filtered_pictures)

    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4 m-auto">
      <%= for picture <- @filtered_pictures do %>
        <.thumbnail picture={picture} checked={Enum.member?(@selected_pictures, picture.id)}/>
      <% end %>
    </div>
    """
  end

  attr(:picture, PictureItem, required: true)
  attr(:checked, :boolean, default: false)

  def thumbnail(assigns) do
    ~H"""
    <div class={Html.class("relative transition cursor-pointer select-none group", {@checked, "scale-90"})} phx-click="picture-click" phx-value-picture_id={@picture.id} phx-value-index={@picture.index}>
      <img class={Html.class("h-full max-h-72 w-full rounded-md shadow-md border-4 group object-cover border-true-gray-300", {@checked, "border-pink-500"})} src={~p(/pictures/#{@picture.id}?#{[type: "thumb"]})} />

      <div class={Html.class("w-full h-full group-hover:bg-gray-500/40 transition p-4 absolute z-10 top-0", [{not @checked, "opacity-0 group-hover:opacity-100"}])}>
        <Ui.select_marker checked={@checked}  on_select="select-picture" on_deselect="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@picture.index} />
      </div>
    </div>
    """
  end

  attr(:visible, :boolean, required: true)
  attr(:selected_pictures, :list, required: true)

  def context_menu(assigns) do
    assigns =
      assigns
      |> assign(:items, [
        {:action, "add-to-album", gettext("Add to album")},
        {:link,
         ~p(/download?#{[pictures: MapSet.to_list(assigns.selected_pictures), type: :jpeg]}),
         gettext("Download JPEG")},
        {:link,
         ~p(/download?#{[pictures: MapSet.to_list(assigns.selected_pictures), type: :original]}),
         gettext("Download original")},
        {:action, "reprocess", gettext("Reprocess")}
      ])
      |> assign(
        :class,
        "cursor-pointer pl-2 py-2 first:rounded-t-lg last:rounded-b-lg transition bg-pink-400 hover:bg-pink-500"
      )
      |> update(:selected_pictures, &MapSet.to_list/1)
      |> update(:visible, &(&1 and Enum.any?(assigns.selected_pictures)))

    ~H"""
    <div class={Html.class("fixed bottom-0 z-30 right-0 flex flex-col m-4 mb-16 text-white w-48 transition", {@visible, "scale-100", "scale-0"})}>
      <%= for {type, action, label} <- @items do %>
        <%= case type do %>
          <% :action -> %>
            <span class={@class} phx-click={action}><%= label %></span>

          <% :link -> %>
            <a href={action} target="_blank" class="cursor-pointer pl-2 py-2 first:rounded-t-lg last:rounded-b-lg transition bg-pink-400 hover:bg-pink-500"><%= label %></a>
        <% end %>
      <% end %>
    </div>
    """
  end
end
