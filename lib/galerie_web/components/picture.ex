defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext

  alias Galerie.Picture
  alias Galerie.Repo
  alias GalerieWeb.Components.Icon
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

  attr(:picture, Picture, required: true)
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

  attr(:picture, Picture, required: true)
  attr(:index, :integer, required: true)
  attr(:selected_pictures, :list, default: [])
  attr(:has_next, :boolean, required: true)
  attr(:has_previous, :boolean, required: true)
  attr(:on_keyup, :string, default: "viewer:keyup")
  attr(:on_close, :string, default: "viewer:close")

  def viewer(assigns) do
    ~H"""
    <div class="z-50 fixed flex flex-row top-0 left-0 w-screen h-screen bg-gray-800/90" phx-window-keyup={@on_keyup}>
      <div class="flex-1 flex flex-row text-white text-lg">
        <.side_arrow disabled={not @has_previous} icon={:left_chevron} on_keyup={@on_keyup} key="ArrowLeft"/>
        <div class="py-2"><img class="h-full m-auto" src={~p(/pictures/#{@picture.id})} /></div>
        <.side_arrow disabled={not @has_next} icon={:right_chevron} on_keyup={@on_keyup} key="ArrowRight"/>
      </div>
      <.info_panel checked={MapSet.member?(@selected_pictures, @picture.id)} picture={@picture} index={@index} on_close={@on_close}/>
    </div>
    """
  end

  attr(:key, :string, required: true)
  attr(:on_keyup, :string, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:icon, :atom, required: true)

  defp side_arrow(assigns) do
    ~H"""
    <div class={Html.class("content-center transition text-gray-400 bg-gray-900/0", {not @disabled, "text-white cursor-pointer hover:bg-gray-900/40"})} phx-click={@on_keyup} phx-value-key={@key}>
      <Icon.icon icon={@icon} width="40" height="40" />
    </div>
    """
  end

  defp info_panel(assigns) do
    assigns = update(assigns, :picture, &Repo.preload(&1, [:picture_exif, :picture_metadata]))

    ~H"""
    <div class="flex flex-col flex-initial w-96 bg-white">
      <div class="flex flex-row justify-between items-center px-4 py-2">
        <span class="text-md flex items-center">
          <Ui.select_marker checked={@checked} class="mr-2" on_select="select-picture" on_deselect="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@picture.index} />
          <%= @picture.name %>
        </span>
        <span class="top-0 right-0 cursor-pointer" phx-click={@on_close}>
          <Icon.cross width="14" height="14" />
        </span>
      </div>
      <%= if @picture.picture_metadata do %>
        <div class="px-4 pt-2 text-sm"><%= @picture.picture_metadata.datetime_original %></div>
        <div class="px-4 pt-2 flex flex-row text-sm justify-between">
          <div class="">
            <%= @picture.picture_metadata.width %>
            <span class="mx-0.5">x</span>
            <%= @picture.picture_metadata.height %>
          </div>
          <%= if @picture.picture_metadata.f_number > 0 do %>
            <div class="">
              <%= gettext("f/%{focal}", focal: @picture.picture_metadata.f_number) %>
            </div>
          <% end %>
          <div class="flex flex-row items-center">
            <Icon.aperture width="18" height="18" class="mr-1" />
            <%= 1 / @picture.picture_metadata.exposure_time %>
          </div>
        </div>
      <% end %>
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
